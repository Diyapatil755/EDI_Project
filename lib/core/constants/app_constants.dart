/// Organization and Attendance Configuration Constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Attendance';
  static const String organizationName = 'VIT Pune Labs';

  // Geofence configuration for VIT Pune campus
  static const double officeLatitude = 18.4636;
  static const double officeLongitude = 73.8682;
  static const double geofenceRadiusMeters = 100.0;

  // Shift timings
  static const String shiftStartTime = '09:30 AM';
  static const String shiftEndTime = '05:30 PM';
  static const int expectedDailyWorkMinutes = 480; // 8 hours

  // Liveness challenge timeout in seconds
  static const int livenessTimeoutSeconds = 12;

  // Security message strings
  static const String msgMockLocation =
      'Mock location detected. Virtual GPS spoofing is prohibited.';
  static const String msgOutsideGeofence =
      'Outside office perimeter. Attendance must be marked inside premises.';
  static const String msgUnregisteredDevice =
      'Unregistered device. Attendance is bound to your registered phone.';
  static const String msgLivenessFailed =
      'Liveness verification challenge incomplete or failed.';
  static const String msgSessionExpired =
      'Authentication session expired. Please sign in again.';

  // ---- Authentication configuration ----

  /// Firestore collection that holds one document per employee (doc id = uid).
  static const String employeesCollection = 'employees';

  /// Employee IDs like EMP-0417 are mapped to EMP-0417@<domain> for login.
  static const String employeeEmailDomain = 'vit.edu';

  /// true  -> real SMS OTP via Firebase Phone Auth (needs Phone sign-in
  ///          enabled in Firebase Console + SHA-1 added for Android).
  /// false -> MockOtpService (development only).
  static const bool useRealOtp = false;

  /// Demo only: create a basic employee profile on first login.
  /// Set to false in production so only the admin panel creates employees.
  static const bool autoCreateEmployeeProfile = true;

  static const String msgDeviceMismatch =
      'This account is registered on another device. Ask your admin to reset it.';
  static const String msgProfileMissing =
      'Your employee profile is not set up. Contact your administrator.';
}
