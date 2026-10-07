import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/attendance_record.dart';
import '../models/evidence_model.dart';
import 'ledger_service.dart';

abstract class AttendanceRepository {
  Future<ServerVerificationResult> submitAttendanceEvidence(
    AttendanceEvidence evidence,
  );
  Future<AttendanceRecord?> getTodayRecord();
  Future<List<AttendanceRecord>> getAttendanceHistory();
  Future<int> syncOfflinePendingRecords();
  Stream<AttendanceRecord?> get todayRecordStream;
}

/// Production & Mockable Attendance Repository.
/// Enforces server decision architecture over client evidence.
class FirebaseAttendanceRepository implements AttendanceRepository {
  final FirebaseFirestore _firestore;
  final LedgerService _ledgerService;
  final StreamController<AttendanceRecord?> _todayStreamController =
      StreamController<AttendanceRecord?>.broadcast();

  // In-memory cache for offline queues & demo history
  final List<AttendanceRecord> _localHistory = [];
  final List<AttendanceEvidence> _offlineQueue = [];
  AttendanceRecord? _todayRecord;

  FirebaseAttendanceRepository({
    FirebaseFirestore? firestore,
    LedgerService? ledgerService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _ledgerService = ledgerService ?? MockLedgerService() {
    _initPersistenceAndSeed();
  }

  void _initPersistenceAndSeed() {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {
      // Persistence already configured
    }
    _seedMockAttendanceHistory();
  }

  void _seedMockAttendanceHistory() {
    // Today record (Not checked in yet initially, or checked in earlier)
    _todayRecord = null;

    // Realistic historical records for September & October 2026
    _localHistory.addAll([
      AttendanceRecord(
        id: 'rec_20261006',
        date: DateTime(2026, 10, 6),
        checkInTime: DateTime(2026, 10, 6, 9, 22),
        checkOutTime: DateTime(2026, 10, 6, 17, 34),
        status: AttendanceStatus.onTime,
        totalWorkMinutes: 492,
        ledgerHash: '0x8f2a1b9c3e4d5f6a7b8c9d0e1f2a3b4c5d6e7f8a',
        ledgerBlockNumber: 4891102,
      ),
      AttendanceRecord(
        id: 'rec_20261005',
        date: DateTime(2026, 10, 5),
        checkInTime: DateTime(2026, 10, 5, 9, 48),
        checkOutTime: DateTime(2026, 10, 5, 17, 45),
        status: AttendanceStatus.late,
        totalWorkMinutes: 477,
        ledgerHash: '0x4e2b9c1d0a8f7e6d5c4b3a2f1e0d9c8b7a6f5e4d',
        ledgerBlockNumber: 4890250,
      ),
      AttendanceRecord(
        id: 'rec_20261003',
        date: DateTime(2026, 10, 3),
        checkInTime: DateTime(2026, 10, 3, 9, 15),
        checkOutTime: DateTime(2026, 10, 3, 17, 28),
        status: AttendanceStatus.onTime,
        totalWorkMinutes: 493,
        ledgerHash: '0x1c3d5e7f9a2b4d6e8f0a2c4e6a8b0d2f4e6a8c0e',
        ledgerBlockNumber: 4888120,
      ),
      AttendanceRecord(
        id: 'rec_20260930',
        date: DateTime(2026, 9, 30),
        checkInTime: DateTime(2026, 9, 30, 9, 10),
        checkOutTime: DateTime(2026, 9, 30, 17, 30),
        status: AttendanceStatus.onTime,
        totalWorkMinutes: 500,
        ledgerHash: '0x992b8d4c1a7e6f3b0e2d5c8a1f4e7b0c3d6a9e2f',
        ledgerBlockNumber: 4875320,
      ),
      AttendanceRecord(
        id: 'rec_20260929',
        date: DateTime(2026, 9, 29),
        checkInTime: DateTime(2026, 9, 29, 9, 25),
        checkOutTime: DateTime(2026, 9, 29, 14, 10),
        status: AttendanceStatus.halfDay,
        totalWorkMinutes: 285,
        ledgerHash: '0x3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c',
        ledgerBlockNumber: 4873190,
      ),
      AttendanceRecord(
        id: 'rec_20260928',
        date: DateTime(2026, 9, 28),
        checkInTime: DateTime(2026, 9, 28, 9, 14),
        checkOutTime: DateTime(2026, 9, 28, 17, 32),
        status: AttendanceStatus.onTime,
        totalWorkMinutes: 498,
        ledgerHash: '0x7e1a3b5d7c9f1a3e5b7d9f1c3e5a7b9d1f3a5c7e',
        ledgerBlockNumber: 4871040,
      ),
    ]);

    _todayStreamController.add(_todayRecord);
  }

  @override
  Stream<AttendanceRecord?> get todayRecordStream =>
      _todayStreamController.stream;

  @override
  Future<AttendanceRecord?> getTodayRecord() async {
    return _todayRecord;
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory() async {
    return List.unmodifiable(_localHistory);
  }

  @override
  Future<ServerVerificationResult> submitAttendanceEvidence(
    AttendanceEvidence evidence,
  ) async {
    // Zero-trust server evaluation simulation:
    // 1. Validate Firebase Auth Token
    if (evidence.idToken.isEmpty || evidence.idToken.contains('expired')) {
      return const ServerVerificationResult(
        isSuccess: false,
        status: ServerDecisionStatus.tokenExpired,
        message: AppConstants.msgSessionExpired,
      );
    }

    // 2. Validate Mock Location
    if (evidence.isMockLocation) {
      return const ServerVerificationResult(
        isSuccess: false,
        status: ServerDecisionStatus.mockLocationDetected,
        message: AppConstants.msgMockLocation,
      );
    }

    // 3. Validate Geofence (Radius: 100 meters)
    if (evidence.distanceToOfficeMeters > AppConstants.geofenceRadiusMeters) {
      return ServerVerificationResult(
        isSuccess: false,
        status: ServerDecisionStatus.outsideGeofence,
        message:
            'Outside office perimeter. You are ${evidence.distanceToOfficeMeters.toStringAsFixed(0)} m from office (limit: 100 m).',
      );
    }

    // 4. Validate Registered Device ID
    if (evidence.deviceId.contains('ROGUE') || evidence.deviceId.contains('UNREGISTERED')) {
      return const ServerVerificationResult(
        isSuccess: false,
        status: ServerDecisionStatus.unregisteredDevice,
        message: AppConstants.msgUnregisteredDevice,
      );
    }

    // 5. Validate Liveness result
    if (!evidence.livenessPassedClaim || evidence.livenessScore < 0.8) {
      return const ServerVerificationResult(
        isSuccess: false,
        status: ServerDecisionStatus.livenessFailed,
        message: AppConstants.msgLivenessFailed,
      );
    }

    // 6. Handle Offline Queuing if submission is marked offline
    if (evidence.isOfflineQueued) {
      _offlineQueue.add(evidence);
      final offlineRecord = AttendanceRecord(
        id: 'queued_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        checkInTime: DateTime.now(),
        status: AttendanceStatus.checkedIn,
        isOfflineQueued: true,
        isSynced: false,
      );
      _todayRecord = offlineRecord;
      _todayStreamController.add(_todayRecord);
      return const ServerVerificationResult(
        isSuccess: true,
        status: ServerDecisionStatus.verified,
        message: 'Attendance saved locally. Will sync when back online.',
      );
    }

    // 7. Legitimate Verified Check-in or Check-out
    final now = DateTime.now();
    final isCheckOut = _todayRecord != null && _todayRecord!.checkOutTime == null;

    final ledgerHash = await _ledgerService.anchorAttendance(
      uid: 'vit_emp_0417_uid',
      timestamp: now,
      type: isCheckOut ? 'CHECK_OUT' : 'CHECK_IN',
    );

    if (isCheckOut) {
      final checkInTime = _todayRecord!.checkInTime ?? now.subtract(const Duration(hours: 8));
      final durationMins = now.difference(checkInTime).inMinutes;

      final updated = _todayRecord!.copyWith(
        checkOutTime: now,
        totalWorkMinutes: durationMins,
        status: durationMins >= 450 ? AttendanceStatus.onTime : AttendanceStatus.earlyDeparture,
        ledgerHash: ledgerHash,
        isSynced: true,
      );
      _todayRecord = updated;
      _localHistory.removeWhere((r) => r.id == updated.id);
      _localHistory.insert(0, updated);
      _todayStreamController.add(_todayRecord);

      return ServerVerificationResult(
        isSuccess: true,
        status: ServerDecisionStatus.verified,
        message: 'Check-out verified and anchored to ledger.',
        ledgerHash: ledgerHash,
        serverTimestamp: now,
      );
    } else {
      final isLate = (now.hour > 9) || (now.hour == 9 && now.minute > 45);
      final newRecord = AttendanceRecord(
        id: 'rec_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
        date: now,
        checkInTime: now,
        status: isLate ? AttendanceStatus.late : AttendanceStatus.checkedIn,
        ledgerHash: ledgerHash,
        isSynced: true,
      );
      _todayRecord = newRecord;
      _localHistory.insert(0, newRecord);
      _todayStreamController.add(_todayRecord);

      return ServerVerificationResult(
        isSuccess: true,
        status: ServerDecisionStatus.verified,
        message: 'Check-in verified and anchored to ledger.',
        ledgerHash: ledgerHash,
        serverTimestamp: now,
      );
    }
  }

  @override
  Future<int> syncOfflinePendingRecords() async {
    if (_offlineQueue.isEmpty) return 0;
    final count = _offlineQueue.length;
    _offlineQueue.clear();

    if (_todayRecord != null && _todayRecord!.isOfflineQueued) {
      final hash = await _ledgerService.anchorAttendance(
        uid: 'vit_emp_0417_uid',
        timestamp: DateTime.now(),
        type: 'CHECK_IN',
      );
      _todayRecord = _todayRecord!.copyWith(
        isOfflineQueued: false,
        isSynced: true,
        ledgerHash: hash,
        ledgerBlockNumber: 4892401,
      );
      _todayStreamController.add(_todayRecord);
    }
    return count;
  }
}
