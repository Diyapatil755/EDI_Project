import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/evidence_model.dart';
import '../../models/liveness_challenge.dart';
import '../../services/attendance_repository.dart';
import '../../services/auth_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/device_service.dart';
import '../../services/face_liveness_service.dart';
import '../../services/location_service.dart';

enum VerificationFlowStep {
  ready,
  faceChallenge,
  submittingEvidence,
  completed,
  rejected,
}

class FaceAttendanceProvider extends ChangeNotifier {
  final FaceLivenessService _faceService;
  final AuthService _authService;
  final LocationService _locationService;
  final DeviceService _deviceService;
  final AttendanceRepository _repository;
  final ConnectivityService _connectivityService;

  VerificationFlowStep _flowStep = VerificationFlowStep.ready;
  LivenessDetectionResult _livenessResult = const LivenessDetectionResult(
    state: LivenessState.idle,
    message: 'Press Start to begin biometric verification',
  );
  ServerVerificationResult? _serverResponse;
  LivenessChallenge _currentChallenge = LivenessChallenge.standardChallenges().first;
  bool _isCameraReady = false;
  StreamSubscription? _livenessSub;

  FaceAttendanceProvider(
    this._faceService,
    this._authService,
    this._locationService,
    this._deviceService,
    this._repository,
    this._connectivityService,
  ) {
    _init();
  }

  VerificationFlowStep get flowStep => _flowStep;
  LivenessDetectionResult get livenessResult => _livenessResult;
  ServerVerificationResult? get serverResponse => _serverResponse;
  LivenessChallenge get currentChallenge => _currentChallenge;
  bool get isCameraReady => _isCameraReady;
  FaceLivenessService get faceService => _faceService;

  Future<void> _init() async {
    _isCameraReady = await _faceService.initializeCamera();
    _livenessSub = _faceService.livenessStream.listen((result) {
      _livenessResult = result;
      notifyListeners();

      if (result.state == LivenessState.success) {
        _handleLivenessPassed(result);
      } else if (result.state == LivenessState.failed ||
          result.state == LivenessState.spoofSuspected) {
        _flowStep = VerificationFlowStep.rejected;
        _serverResponse = ServerVerificationResult(
          isSuccess: false,
          status: result.state == LivenessState.spoofSuspected
              ? ServerDecisionStatus.livenessFailed
              : ServerDecisionStatus.livenessFailed,
          message: result.failureReason ?? 'Liveness check did not pass.',
        );
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void selectChallenge(LivenessChallenge challenge) {
    _currentChallenge = challenge;
    notifyListeners();
  }

  Future<void> startVerification() async {
    _flowStep = VerificationFlowStep.faceChallenge;
    _serverResponse = null;
    notifyListeners();

    await _faceService.startLivenessSession(_currentChallenge);
  }

  Future<void> _handleLivenessPassed(LivenessDetectionResult liveness) async {
    _flowStep = VerificationFlowStep.submittingEvidence;
    notifyListeners();

    try {
      // 1. Fetch Fresh Auth ID Token (never sending plain employeeId)
      final idToken = await _authService.getIdToken() ?? '';

      // 2. Fetch Device Hardware Telemetry
      final device = await _deviceService.getDeviceMetadata();

      // 3. Fetch GPS Location Telemetry
      final location = await _locationService.getCurrentTelemetry();

      // 4. Check network connectivity
      final isOnline = await _connectivityService.checkIsOnline();

      // 5. Generate random anti-replay cryptographic nonce
      final nonce = 'NONCE-${Random().nextInt(99999999)}-${DateTime.now().millisecondsSinceEpoch}';

      final evidence = AttendanceEvidence(
        idToken: idToken,
        deviceId: device.deviceId,
        deviceModel: device.modelName,
        latitude: location.latitude,
        longitude: location.longitude,
        accuracyMeters: location.accuracyMeters,
        isMockLocation: location.isMockLocation,
        distanceToOfficeMeters: location.distanceToOfficeMeters,
        challengeType: _currentChallenge.type.name,
        livenessPassedClaim: true,
        livenessScore: liveness.confidenceScore,
        nonce: nonce,
        clientTimestamp: DateTime.now(),
        isOfflineQueued: !isOnline,
      );

      // Submit bundle to server decision pipeline
      final response = await _repository.submitAttendanceEvidence(evidence);
      _serverResponse = response;
      _flowStep = response.isSuccess
          ? VerificationFlowStep.completed
          : VerificationFlowStep.rejected;
    } catch (e) {
      _flowStep = VerificationFlowStep.rejected;
      _serverResponse = ServerVerificationResult(
        isSuccess: false,
        status: ServerDecisionStatus.networkError,
        message: 'Network verification failed: $e',
      );
    }
    notifyListeners();
  }

  Future<void> resetVerification() async {
    await _faceService.cancelLivenessSession();
    _flowStep = VerificationFlowStep.ready;
    _serverResponse = null;
    _livenessResult = const LivenessDetectionResult(
      state: LivenessState.idle,
      message: 'Press Start to begin biometric verification',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _livenessSub?.cancel();
    _faceService.dispose();
    super.dispose();
  }
}
