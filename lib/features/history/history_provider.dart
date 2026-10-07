import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../services/attendance_repository.dart';
import '../../services/ledger_service.dart';

class HistoryProvider extends ChangeNotifier {
  final AttendanceRepository _repository;
  final LedgerService _ledgerService;

  List<AttendanceRecord> _records = [];
  bool _isLoading = false;
  String? _error;
  LedgerTransactionDetails? _inspectedTx;
  bool _isLoadingTx = false;

  HistoryProvider(
    this._repository,
    this._ledgerService,
  ) {
    loadHistory();
  }

  List<AttendanceRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LedgerTransactionDetails? get inspectedTx => _inspectedTx;
  bool get isLoadingTx => _isLoadingTx;

  Map<String, List<AttendanceRecord>> get groupedByMonth {
    final Map<String, List<AttendanceRecord>> map = {};
    for (final record in _records) {
      final key = record.monthYearHeader;
      map.putIfAbsent(key, () => []).add(record);
    }
    return map;
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await _repository.getAttendanceHistory();
    } catch (e) {
      _error = 'Failed to load attendance logs';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> inspectLedgerHash(String txHash) async {
    _isLoadingTx = true;
    _inspectedTx = null;
    notifyListeners();

    try {
      _inspectedTx = await _ledgerService.getTransactionDetails(txHash);
    } catch (_) {}

    _isLoadingTx = false;
    notifyListeners();
  }
}
