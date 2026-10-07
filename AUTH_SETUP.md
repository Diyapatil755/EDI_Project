# Authentication setup (Firebase)

## Firebase Console (Miheer / project owner)
1. Authentication -> Sign-in method -> **Email/Password ON**.
2. Firestore Database -> Create database. Rules tab -> paste `firestore.rules` -> Publish.
3. Create each employee: Authentication -> Users -> Add user (email = `EMP-0417@vit.edu`, password).
4. (Optional but recommended) Firestore -> `employees/{uid}` document with fields:
   employeeId, fullName, email, department, role ("Employee"), phone ("+91XXXXXXXXXX").
   If missing, a basic profile is auto-created on first login (AppConstants.autoCreateEmployeeProfile).

## OTP (real SMS)
1. Authentication -> Sign-in method -> **Phone ON**.
2. Project settings -> Your apps (Android) -> add **SHA-1 and SHA-256**.
3. In `lib/core/constants/app_constants.dart` set `useRealOtp = true`.
4. Employee doc must have `phone` in +91XXXXXXXXXX format.
Phone OTP does not work on Windows desktop or plain Chrome testing; keep `useRealOtp = false` there.

## Reset a device (admin)
Firestore -> employees/{uid} -> delete `registeredDeviceId` and `registeredDeviceModel`.
The employee's next login asks them to register the new phone.

## How it works
- Login: Firebase email/password. Wrong id and wrong password give the same message.
- Device check happens BEFORE OTP: a different phone is signed out immediately.
- OTP: Firebase Phone Auth, re-verified on every login. Session is only restored if OTP
  was completed on this phone (stored securely).
- Server identity: uses the Firebase ID token (`AuthService.getIdToken`). The app never
  sends an employee id as truth.

## Still NOT real (needs Miheer / Ronak)
- `FirebaseAttendanceRepository.submitAttendanceEvidence` checks token/GPS/device/liveness
  inside the app. Real enforcement must be a Cloud Function (or backend) that verifies the
  ID token, compares deviceId with employees/{uid}.registeredDeviceId, re-checks geofence,
  and writes the attendance record. Client-side checks can be bypassed.
- Blockchain ledger is still MockLedgerService.
