/// Evidence submitted by the client when marking attendance.
/// In accordance with the zero-trust security question:
/// "The client is never the source of truth."
/// The client sends this bundle of cryptographic and sensor evidence,
/// but only the server verifies authenticity and authorizes the attendance claim.
class AttendanceEvidence {
  /// Firebase Auth ID token (server unpacks UID, never trusts client employeeId)
  final String idToken;

  /// Hardware identifier from secure storage / device info
  final String deviceId;
  final String deviceModel;

  /// GPS Location Telemetry
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final bool isMockLocation;
  final double distanceToOfficeMeters;

  /// Face Liveness Challenge Evidence
  final String challengeType;
  final bool livenessPassedClaim;
  final double livenessScore;

  /// Anti-replay cryptographic nonce & client timestamp
  final String nonce;
  final DateTime clientTimestamp;
  final bool isOfflineQueued;

  const AttendanceEvidence({
    required this.idToken,
    required this.deviceId,
    required this.deviceModel,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.isMockLocation,
    required this.distanceToOfficeMeters,
    required this.challengeType,
    required this.livenessPassedClaim,
    required this.livenessScore,
    required this.nonce,
    required this.clientTimestamp,
    this.isOfflineQueued = false,
  });

  Map<String, dynamic> toEvidencePayload() {
    return {
      'idToken': idToken,
      'device': {
        'id': deviceId,
        'model': deviceModel,
      },
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracyMeters,
        'isMock': isMockLocation,
        'distanceMeters': distanceToOfficeMeters,
      },
      'liveness': {
        'challenge': challengeType,
        'claimedResult': livenessPassedClaim,
        'confidence': livenessScore,
      },
      'security': {
        'nonce': nonce,
        'timestamp': clientTimestamp.toIso8601String(),
        'isOfflineQueued': isOfflineQueued,
      },
    };
  }
}

/// Server decision result returned after evaluating the client's evidence bundle.
enum ServerDecisionStatus {
  verified,
  unregisteredDevice,
  outsideGeofence,
  mockLocationDetected,
  livenessFailed,
  tokenExpired,
  rateLimited,
  networkError,
}

class ServerVerificationResult {
  final bool isSuccess;
  final ServerDecisionStatus status;
  final String message;
  final String? ledgerHash;
  final DateTime? serverTimestamp;

  const ServerVerificationResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    this.ledgerHash,
    this.serverTimestamp,
  });
}
