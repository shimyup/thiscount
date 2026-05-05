# Play Console Data Safety (Checkbox Values, Final)

Last updated: 2026-04-01  
Basis: current `Thiscount` codebase (Bundle ID `io.thiscount`) + release build scripts (`FIREBASE_*`, `REVENUECAT_*` required)

Use this in **Play Console > App content > Data safety**.

## A) Top-level questions

1. **Does your app collect or share any of the required user data types?**  
   - Select: `Yes`

2. **Is all of the user data collected by your app encrypted in transit?**  
   - Select: `Yes`

3. **Do you provide a way for users to request that their data is deleted?**  
   - Select: `No`
   - Reason: local delete exists, but remote Firestore data deletion request flow is not fully implemented in-app.

## B) Data types: mark as Collected (checkbox-level)

For the items below, set **Collected = Yes**.

### 1) Personal info > Name
- Collected: `Yes`
- Shared: `No`
- Is this data processed ephemerally?: `No`
- Is collection required or optional?: `Required`
- Purposes:
  - `App functionality`
  - `Account management`

### 2) Personal info > User IDs
- Collected: `Yes`
- Shared: `No`
- Is this data processed ephemerally?: `No`
- Is collection required or optional?: `Required`
- Purposes:
  - `App functionality`
  - `Account management`
  - `Fraud prevention, security, and compliance`

### 3) Location > Precise location
- Collected: `Yes`
- Shared: `No`
- Is this data processed ephemerally?: `No`
- Is collection required or optional?: `Optional`
- Purposes:
  - `App functionality`

### 4) Financial info > Purchase history
- Collected: `Yes`
- Shared: `No`
- Is this data processed ephemerally?: `No`
- Is collection required or optional?: `Optional`
- Purposes:
  - `App functionality`
  - `Fraud prevention, security, and compliance`

### 5) Messages > Other in-app messages
- Collected: `Yes`
- Shared: `Yes`
- Is this data processed ephemerally?: `No`
- Is collection required or optional?: `Optional`
- Purposes:
  - `App functionality`

### 6) Device or other IDs > Device or other IDs
- Collected: `Yes`
- Shared: `No`
- Is this data processed ephemerally?: `No`
- Is collection required or optional?: `Required`
- Purposes:
  - `App functionality`
  - `Fraud prevention, security, and compliance`

## C) Data types: mark as Not Collected

Set these to `Not collected`:

- Personal info > Email address (off-device)
- Personal info > Phone number
- Financial info > Credit score
- Health and fitness
- Photos and videos (off-device upload path not used in current release)
- Audio files
- Files and docs
- Calendar
- Contacts
- App activity > App interactions
- App info and performance > Crash logs
- Device or other IDs > Advertising ID

## D) Ads declaration

- **Does your app use advertising?**  
  - Select: `No`

## E) Final consistency checks before submit

1. If you remove translation API usage, switch `Messages > Other in-app messages` accordingly.
2. If you add off-device email storage/auth linkage, switch `Email address` to collected.
3. If you add image upload/storage, switch `Photos and videos` to collected.
4. If you implement remote account deletion request, change deletion question to `Yes`.
