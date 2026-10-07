import 'package:intl/intl.dart';

enum AttendanceStatus {
  onTime,
  late,
  earlyDeparture,
  checkedIn,
  halfDay,
}

/// A finalized or offline-pending attendance log entry.
class AttendanceRecord {
  final String id;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final int totalWorkMinutes;
  final bool isOfflineQueued;
  final bool isSynced;
  final String? ledgerHash;
  final int? ledgerBlockNumber;

  const AttendanceRecord({
    required this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.status = AttendanceStatus.onTime,
    this.totalWorkMinutes = 0,
    this.isOfflineQueued = false,
    this.isSynced = true,
    this.ledgerHash,
    this.ledgerBlockNumber,
  });

  String get formattedDate => DateFormat('EEE, d MMM yyyy').format(date);
  String get monthYearHeader => DateFormat('MMMM yyyy').format(date);

  String get formattedCheckIn =>
      checkInTime != null ? DateFormat('hh:mm a').format(checkInTime!) : '--:--';

  String get formattedCheckOut =>
      checkOutTime != null ? DateFormat('hh:mm a').format(checkOutTime!) : '--:--';

  String get formattedDuration {
    final hours = totalWorkMinutes ~/ 60;
    final mins = totalWorkMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} hrs';
  }

  String get shortLedgerHash {
    if (ledgerHash == null || ledgerHash!.isEmpty) return '';
    if (ledgerHash!.length <= 12) return ledgerHash!;
    return '${ledgerHash!.substring(0, 6)}...${ledgerHash!.substring(ledgerHash!.length - 4)}';
  }

  AttendanceRecord copyWith({
    String? id,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    AttendanceStatus? status,
    int? totalWorkMinutes,
    bool? isOfflineQueued,
    bool? isSynced,
    String? ledgerHash,
    int? ledgerBlockNumber,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      totalWorkMinutes: totalWorkMinutes ?? this.totalWorkMinutes,
      isOfflineQueued: isOfflineQueued ?? this.isOfflineQueued,
      isSynced: isSynced ?? this.isSynced,
      ledgerHash: ledgerHash ?? this.ledgerHash,
      ledgerBlockNumber: ledgerBlockNumber ?? this.ledgerBlockNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'status': status.name,
      'totalWorkMinutes': totalWorkMinutes,
      'isOfflineQueued': isOfflineQueued,
      'isSynced': isSynced,
      'ledgerHash': ledgerHash,
      'ledgerBlockNumber': ledgerBlockNumber,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      checkInTime: map['checkInTime'] != null
          ? DateTime.parse(map['checkInTime'] as String)
          : null,
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.parse(map['checkOutTime'] as String)
          : null,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.onTime,
      ),
      totalWorkMinutes: map['totalWorkMinutes'] as int? ?? 0,
      isOfflineQueued: map['isOfflineQueued'] as bool? ?? false,
      isSynced: map['isSynced'] as bool? ?? true,
      ledgerHash: map['ledgerHash'] as String?,
      ledgerBlockNumber: map['ledgerBlockNumber'] as int?,
    );
  }
}
