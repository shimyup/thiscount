#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

branch="$(git branch --show-current)"
if [[ "$branch" == "main" || "$branch" == "master" ]]; then
  echo "[branch] FAIL: currently on '$branch'."
  echo "[branch] switch to a feature branch before staging/committing."
  exit 1
fi

echo "[branch] OK: current branch is '$branch'."
