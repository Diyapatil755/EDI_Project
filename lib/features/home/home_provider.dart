import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../services/attendance_repository.dart';
import '../../services/connectivity_service.dart';
import '../../services/device_service.dart';
import '../../services/location_service.dart';

class HomeProvider extends ChangeNotifier {
  final AttendanceRepository _repository;
  final LocationService _locationService;
  final ConnectivityService _connectivityService;
  final DeviceService _deviceService;

  AttendanceRecord? _todayRecord;
  LocationTelemetry? _currentLocation;
  bool _isOnline = true;
  bool _isLoading = false;
  int _syncedOfflineCount = 0;
  Timer? _workTimer;
  StreamSubscription? _connectivitySub;
  StreamSubscription? _todaySub;

  HomeProvider(
    this._repository,
    this._locationService,
    this._connectivityService,
    this._deviceService,
  ) {
    _init();
  }

  AttendanceRecord? get todayRecord => _todayRecord;
  LocationTelemetry? get currentLocation => _currentLocation;
  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  int get syncedOfflineCount => _syncedOfflineCount;
  DeviceService get deviceService => _deviceService;
  LocationService get locationService => _locationService;

  bool get isCheckedIn =>
      _todayRecord != null && _todayRecord!.checkInTime != null;

  bool get isCheckedOut =>
      _todayRecord != null && _todayRecord!.checkOutTime != null;

  String get timeWorkedToday {
    if (_todayRecord == null || _todayRecord!.checkInTime == null) {
      return '00:00 hrs';
    }
    final now = _todayRecord!.checkOutTime ?? DateTime.now();
    final diff = now.difference(_todayRecord!.checkInTime!);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} hrs';
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _isOnline = await _connectivityService.checkIsOnline();
    _currentLocation = await _locationService.getCurrentTelemetry();
    _todayRecord = await _repository.getTodayRecord();

    _connectivitySub = _connectivityService.onConnectivityChanged.listen((online) {
      _isOnline = online;
      if (online) {
        _syncPendingOffline();
      }
      notifyListeners();
    });

    _todaySub = _repository.todayRecordStream.listen((record) {
      _todayRecord = record;
      notifyListeners();
    });

    _workTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (isCheckedIn && !isCheckedOut) {
        notifyListeners();
      }
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    _currentLocation = await _locationService.getCurrentTelemetry();
    notifyListeners();
  }

  Future<void> _syncPendingOffline() async {
    final count = await _repository.syncOfflinePendingRecords();
    if (count > 0) {
      _syncedOfflineCount += count;
      _todayRecord = await _repository.getTodayRecord();
      notifyListeners();
    }
  }

  // Simulation controls for evaluation
  void toggleGeofenceSimulation(bool inside) {
    _locationService.setSimulatedDistanceMeters(inside ? 35.0 : 140.0);
    refreshLocation();
  }

  void toggleMockLocationSimulation(bool isMock) {
    _locationService.setSimulatedMockLocation(isMock);
    refreshLocation();
  }

  void toggleDeviceMismatchSimulation(bool mismatch) {
    _deviceService.setSimulationMismatched(mismatch);
    notifyListeners();
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    _connectivitySub?.cancel();
    _todaySub?.cancel();
    super.dispose();
  }
}
