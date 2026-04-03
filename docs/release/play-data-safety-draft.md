# Google Play Data Safety Draft (Code-Based)

Date: 2026-04-01  
Scope: current `Lettergo` codebase

This draft is a practical starting point for the Play Console Data safety form.  
Final submission should be reviewed with legal/policy owner.

## 1) Data Collected / Shared (Draft)

| Data Type (Play category) | Collected (off-device) | Shared | Purpose | Notes |
|---|---|---|---|---|
| Personal info > User IDs | Yes | No | App functionality, account management, fraud prevention | `userId` stored and used in Firestore user/purchase claim docs |
| Personal info > Email address | No (current local auth flow) | No | Account login (on-device) | Email is stored in secure local storage; not sent to Firestore in current flow |
| Location > Precise location | Yes | No | App functionality | Latitude/longitude saved to Firestore for map/tower placement |
| Financial info > Purchase history | Yes | No | Purchases, fraud prevention, security | Transaction ID/product ID used for brand-extra server verification; RevenueCat handles subscription processing |
| App info and performance > Crash logs | No (SDK not present) | No | - | No Crashlytics/Sentry SDK found in current code |
| Messages | No (off-device) | No | - | Letter content currently persisted locally in app state/prefs |
| Photos and videos | No (off-device) | No | - | Image selection is local; no upload pipeline found in current code |
| Device or other IDs > Advertising ID | No | No | - | Ads SDK not found |

## 2) Security Practices (Draft)

- Data encrypted in transit: **Yes**
  - Firebase/Google APIs and RevenueCat endpoints are HTTPS.
- Data deletion request support: **Needs policy decision**
  - Local account deletion exists (`AuthService.deleteAccount`) and clears local data.
  - Remote Firestore user docs are not explicitly deleted by current in-app flow.
  - Recommend adding server-side account deletion flow before final declaration if "User can request deletion" is selected.

## 3) Third-Party Processors Used

- RevenueCat (`purchases_flutter`)
- Firebase Auth/Firestore REST APIs (when enabled)

No ads SDK detected.

## 4) Form Input Recommendation (Conservative)

If you want the safest compliance position for initial release:
1. Mark **User IDs**, **Precise location**, **Purchase history** as collected.
2. Mark **not sold**, **not used for advertising**.
3. Mark **data is encrypted in transit**.
4. For deletion section, select the option that matches current implementation exactly.

## 5) Pre-Submit Validation Checklist

- Confirm production build actually uses the same auth flow as current code.
- Confirm no hidden analytics/crash SDK in native project files.
- Re-check Firestore fields in release build:
  - `id`, `username`, `countryFlag`, `country`, `latitude`, `longitude`
  - invite and purchase claim fields
- If backend behavior changed, update this document before console submission.
