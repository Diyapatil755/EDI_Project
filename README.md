# Smart Attendance System — Employee Mobile App

**VIT Pune | Software Engineering Project**  
Flutter (Dart) + Firebase | Employee-side mobile frontend

---

## Project Overview

This is the **employee-facing mobile frontend** for Smart Attendance System, a zero-trust biometric attendance platform for micro-organisations (5–50 employees). Attendance is verified through a chain of independent evidence:

1. Firebase Auth ID Token (server resolves employee from token UID — never from a client-supplied `employeeId`)
2. GPS geofence (100 m radius, VIT Pune campus)
3. Mock-location detection
4. Face liveness challenge (blink / head-turn)
5. Single registered device (one device per account)
6. 6-digit OTP verification on every login

---

## Architecture

```
lib/
├── core/
│   ├── constants/       # AppColors, AppSpacing, AppConstants
│   ├── theme/           # AppTheme (IBM Plex Sans, flat 1px borders)
│   └── widgets/         # AppCard, AppButton, AppTextField, AppBanner, StatusBadge, EmptyStateView
│
├── models/              # EmployeeModel, AttendanceRecord, AttendanceEvidence, LivenessChallenge
│
├── services/            # All service interfaces + implementations
│   ├── auth_service.dart
│   ├── otp_service.dart
│   ├── device_service.dart
│   ├── location_service.dart
│   ├── face_liveness_service.dart
│   ├── attendance_repository.dart
│   ├── ledger_service.dart
│   └── connectivity_service.dart
│
├── features/
│   ├── auth/            # Splash, Login, OTP Verification, Device Registration
│   ├── home/            # Dashboard with today's status, geofence, punch times
│   ├── face/            # Face liveness flow, oval camera portal, challenge prompts
│   ├── history/         # Monthly-grouped attendance log with ledger hash chips
│   ├── profile/         # Employee details, registered device, logout
│   └── main_shell.dart  # Bottom navigation (Home / Face Attendance / History / Profile)
│
└── main.dart            # Firebase init, MultiProvider, AuthFlowCoordinator
```

State management: **Provider** (ChangeNotifier). No `setState` outside UI-only leaf widgets.

---

## Screens Summary

| # | Screen | Key Security States |
|---|--------|---------------------|
| 1 | Splash | Session check animation |
| 2 | Login | Generic `"Invalid employee ID or password"` error, show/hide password, forgot-password |
| 3 | OTP Verification | 6-digit input, 45-second resend timer, wrong-code state |
| 4 | Device Registration | Hardware telemetry, 1-device policy explanation |
| 5 | Home | Geofence live status, offline banner, security device indicator |
| 6 | Face Attendance | Oval guide, blink/head-turn challenges, spoof-suspected, token-expired force re-login |
| 7 | History | Month-grouped list, ledger hash chip, empty state |
| 8 | Profile | Employee details, registered device, logout with confirmation |

---

## Security Architecture

> **"The client is never the source of truth."**

- The app sends a **cryptographic evidence bundle** (ID token + device ID + GPS telemetry + liveness confidence score + anti-replay nonce) to the server.
- The server **derives** the employee identity from the verified Firebase Auth UID — the client never sends an `employeeId` as a trusted field.
- **No `isFaceMatched = true`** is written directly to Firestore from the app.
- The `ServerVerificationResult` carries back the decision; the UI surfaces specific rejection reasons:

| Rejection State | UI Message |
|---|---|
| Unregistered device | "Device Security Violation" |
| Outside geofence | "Geofence Perimeter Rejection" |
| Mock / virtual GPS | "Anti-Spoofing GPS Trigger" |
| Liveness failed | "Biometric Liveness Failed" |
| Token expired | "Authentication Session Expired" → force re-login |

---

## Mocked Services — What Each Teammate Must Replace

| Service | File | Currently Mocked | Teammate Replaces With |
|---|---|---|---|
| **OTP** | `services/otp_service.dart` | `MockOtpService` — accepts `417892` or `123456` | Twilio SMS / Firebase Phone Auth / enterprise SMTP |
| **Face Liveness** | `services/face_liveness_service.dart` | `CameraMlKitFaceLivenessService` with simulated outcome timers | Real Google ML Kit face detection with `EyeOpenProbability`, head-rotation Euler angles, and anti-spoofing logic |
| **Blockchain Ledger** | `services/ledger_service.dart` | `MockLedgerService` — generates SHA-256 mock hashes | Polygon / Ethereum contract calls; replace `anchorAttendance()` and `getTransactionDetails()` |
| **Device Binding** | `services/device_service.dart` | `AppDeviceService` — uses `flutter_secure_storage` for device ID | Can remain as-is for Android/iOS; server must compare against the registered device stored server-side |
| **Attendance Verification** | `services/attendance_repository.dart` | `FirebaseAttendanceRepository` — simulates server decisions locally | Route `submitAttendanceEvidence()` to a real FastAPI/Express backend endpoint that verifies the Firebase ID token, checks device, geofence, and liveness confidence server-side |
| **Geofence** | `services/location_service.dart` | `GeoLocationService` with simulation toggle | Works in production; admin sets lat/lng via admin panel — update `AppConstants.officeLatitude/officeLongitude` |

---

## Demo Credentials

```
Employee ID : EMP-0417  (or aarav.deshmukh@vit.edu)
Password    : pass1234  (any ≥6 chars in mock mode)
OTP Code    : 417892    (or universal: 123456)
```

---

## Running the App

```bash
# Install dependencies
dart pub get

# Run on Android / iOS
flutter run

# Run on Chrome (web demo — camera and ML Kit fall back to mock)
flutter run -d chrome

# Static analysis (must be clean)
flutter analyze        # → No issues found!

# Widget tests
flutter test           # → All tests passed!
```

---

## Demo Simulation Controls

A **tune icon** in the Home app bar opens a simulation panel where teammates can toggle:

- **Outside Geofence** — sets simulated distance to 140 m (exceeds 100 m limit)
- **Mock / Virtual GPS** — triggers anti-spoofing server rejection
- **Unregistered / Rogue Phone** — simulates device binding mismatch

The **bug icon** in Face Attendance opens:

- **Simulate Successful Liveness** — normal check-in/out flow
- **Simulate Photo / Screen Spoofing** — spoof-suspected state
- **Simulate Liveness Timeout** — failed challenge state

---

## Design System

| Token | Value |
|---|---|
| Primary Blue | `#1565C0` |
| Light Blue Tint | `#EAF2FB` |
| Text Primary | `#1C334E` |
| Text Secondary | `#5C728A` |
| Success | `#2E7D32` |
| Error | `#B03A2E` |
| Border | `#D9E2EC` |
| Typeface | IBM Plex Sans (via `google_fonts`) |
| Spacing grid | 8pt (`AppSpacing`) |
| Radius | 8–10 px |
| Min touch target | 48 dp |

---

## Packages Used

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^3.6.0 | Firebase initialization |
| `firebase_auth` | ^5.3.1 | Authentication + ID token |
| `cloud_firestore` | ^5.4.4 | Offline persistence |
| `camera` | ^0.11.0+2 | Front camera preview |
| `google_mlkit_face_detection` | ^0.13.0 | Face + liveness analysis |
| `geolocator` | ^13.0.1 | GPS telemetry |
| `device_info_plus` | ^11.1.0 | Hardware device metadata |
| `flutter_secure_storage` | ^9.2.2 | Encrypted device ID binding |
| `connectivity_plus` | ^6.1.0 | Online/offline detection |
| `crypto` | ^3.0.3 | SHA-256 mock ledger hashes |
| `google_fonts` | ^6.2.1 | IBM Plex Sans typography |
| `intl` | ^0.19.0 | Date/time formatting |
| `provider` | ^6.1.2 | State management |

---

*Admin panel, geofence configuration, and blockchain ledger anchoring are built by separate teammates and are not included in this repository.*
