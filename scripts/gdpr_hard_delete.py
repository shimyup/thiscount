#!/usr/bin/env python3
"""
GDPR / KISA hard-delete cron job — Build 281 (P0)

Background
----------
회원 탈퇴 시 클라이언트의 `FirestoreService.scrubLettersBySender` 가
본인이 보낸 letters 의 `status` 를 `deletedBySender` 로 mark 한다.
firestore.rules 의 화이트리스트 때문에 클라이언트가 본문/좌표/발신자ID
같은 PII 필드를 직접 지울 수 없어, 메타데이터가 영구 잔존하는 GDPR /
CCPA / KISA 위반 리스크가 있다 (Build 277 audit P0 #4).

This script
-----------
service account 권한으로 Firestore REST 를 호출해서

    status == "deletedBySender" AND
    arrivedAt   <= now - GRACE_DAYS (default 30)

조건을 만족하는 모든 letter 문서를 **완전 삭제** 한다.
이미 mark 후 30일 (= 사용자 데이터 회복 요청 grace period) 이 지났으면
GDPR Art.17 (right to erasure) + KISA 정보통신망법 제29조의2 (파기
의무) 를 모두 만족한다.

Setup
-----
1. Firebase Console → Project settings → Service accounts →
   "Generate new private key" 로 JSON 파일 발급.
2. 환경 변수 설정 :

       export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
       export FIREBASE_PROJECT_ID=lettergo-147eb  # .env.local 과 동일

3. 의존성 (시스템 python3.10+ 면 OK) :

       pip install google-auth google-auth-httplib2 requests

Usage
-----
    # dry-run (실제 삭제 안 함, 후보만 출력) :
    python3 scripts/gdpr_hard_delete.py --dry-run

    # 실제 hard-delete :
    python3 scripts/gdpr_hard_delete.py

    # 기간 조정 (기본 30일, 테스트 시 0 가능) :
    python3 scripts/gdpr_hard_delete.py --grace-days 30

Cron
----
정식 launch 후 매일 03:00 UTC 실행 권장 :

    0 3 * * * cd /opt/thiscount && python3 scripts/gdpr_hard_delete.py >> /var/log/thiscount-gdpr.log 2>&1

Migration plan
--------------
이 스크립트는 즉시 가능한 임시 인프라다. 다음 sprint 에 Cloud Functions
(`functions/index.ts` + `onSchedule("every 24 hours")` ) 로 마이그레이션해
서 외부 cron 인프라 없이도 자동 실행되게 한다.
"""

from __future__ import annotations

import argparse
import datetime as dt
import os
import sys
from typing import Any, Iterable

try:
    import google.auth  # type: ignore
    import google.auth.transport.requests  # type: ignore
    import requests  # type: ignore
except ImportError:
    sys.stderr.write(
        "[gdpr_hard_delete] missing deps. run:\n"
        "  pip install google-auth google-auth-httplib2 requests\n"
    )
    sys.exit(2)


PROJECT_ID = os.environ.get("FIREBASE_PROJECT_ID", "").strip()
if not PROJECT_ID:
    sys.stderr.write(
        "[gdpr_hard_delete] FIREBASE_PROJECT_ID env var required.\n"
    )
    sys.exit(2)

if not os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
    sys.stderr.write(
        "[gdpr_hard_delete] GOOGLE_APPLICATION_CREDENTIALS env var required\n"
        "  (path to service-account JSON, see top-of-file docstring).\n"
    )
    sys.exit(2)


FIRESTORE_BASE = (
    f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
    f"/databases/(default)/documents"
)
RUNQUERY_URL = (
    f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
    f"/databases/(default)/documents:runQuery"
)


def _access_token() -> str:
    creds, _ = google.auth.default(
        scopes=["https://www.googleapis.com/auth/datastore"]
    )
    creds.refresh(google.auth.transport.requests.Request())
    return creds.token


def _headers(token: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }


def _stringify_ts(ts: dt.datetime) -> str:
    # Firestore expects RFC3339 with "Z" suffix.
    return ts.astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")


def _query_candidates(
    token: str, cutoff: dt.datetime
) -> Iterable[dict[str, Any]]:
    """status == deletedBySender AND arrivedAt <= cutoff."""
    body = {
        "structuredQuery": {
            "from": [{"collectionId": "letters"}],
            "where": {
                "compositeFilter": {
                    "op": "AND",
                    "filters": [
                        {
                            "fieldFilter": {
                                "field": {"fieldPath": "status"},
                                "op": "EQUAL",
                                "value": {"stringValue": "deletedBySender"},
                            }
                        },
                        {
                            "fieldFilter": {
                                "field": {"fieldPath": "arrivedAt"},
                                "op": "LESS_THAN_OR_EQUAL",
                                "value": {
                                    "timestampValue": _stringify_ts(cutoff)
                                },
                            }
                        },
                    ],
                }
            },
            "limit": 500,
        }
    }
    resp = requests.post(RUNQUERY_URL, headers=_headers(token), json=body)
    resp.raise_for_status()
    for row in resp.json():
        if "document" in row:
            yield row["document"]


def _delete_document(token: str, name: str) -> bool:
    # name format: "projects/.../documents/letters/{id}"
    url = f"https://firestore.googleapis.com/v1/{name}"
    resp = requests.delete(url, headers=_headers(token))
    if resp.status_code in (200, 204):
        return True
    sys.stderr.write(
        f"[gdpr_hard_delete] DELETE {name} failed: "
        f"{resp.status_code} {resp.text[:200]}\n"
    )
    return False


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="후보만 출력, 실제 삭제 안 함",
    )
    ap.add_argument(
        "--grace-days",
        type=int,
        default=30,
        help="회원 탈퇴 후 hard-delete 까지 grace period (일, 기본 30)",
    )
    args = ap.parse_args()

    cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(
        days=args.grace_days
    )
    print(
        f"[gdpr_hard_delete] cutoff = {_stringify_ts(cutoff)} "
        f"({args.grace_days}d ago)"
    )

    token = _access_token()
    print("[gdpr_hard_delete] service account token acquired")

    total = 0
    deleted = 0
    for doc in _query_candidates(token, cutoff):
        total += 1
        name = doc.get("name", "")
        letter_id = name.rsplit("/", 1)[-1] if name else "?"
        arrived = (
            doc.get("fields", {})
            .get("arrivedAt", {})
            .get("timestampValue", "?")
        )
        sender = (
            doc.get("fields", {})
            .get("senderId", {})
            .get("stringValue", "?")
        )
        print(
            f"  candidate: letterId={letter_id} senderId={sender} "
            f"arrivedAt={arrived}"
        )
        if args.dry_run:
            continue
        if _delete_document(token, name):
            deleted += 1

    print(
        f"[gdpr_hard_delete] done — candidates={total} "
        f"deleted={deleted}{' (dry-run)' if args.dry_run else ''}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
