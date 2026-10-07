/// Represents an organization employee profile.
/// Server derives employee record from Firebase Auth UID.
class EmployeeModel {
  final String uid;
  final String employeeId; // e.g. EMP-0417
  final String fullName;   // e.g. Aarav Deshmukh
  final String email;
  final String department;
  final String role;
  final String? phone; // E.164, e.g. +919876543210
  final String? registeredDeviceId;
  final String? registeredDeviceModel;
  final DateTime joinedDate;

  const EmployeeModel({
    required this.uid,
    required this.employeeId,
    required this.fullName,
    required this.email,
    required this.department,
    required this.role,
    this.phone,
    this.registeredDeviceId,
    this.registeredDeviceModel,
    required this.joinedDate,
  });

  bool get hasRegisteredDevice =>
      registeredDeviceId != null && registeredDeviceId!.isNotEmpty;

  EmployeeModel copyWith({
    String? uid,
    String? employeeId,
    String? fullName,
    String? email,
    String? department,
    String? role,
    String? phone,
    String? registeredDeviceId,
    String? registeredDeviceModel,
    DateTime? joinedDate,
  }) {
    return EmployeeModel(
      uid: uid ?? this.uid,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      department: department ?? this.department,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      registeredDeviceId: registeredDeviceId ?? this.registeredDeviceId,
      registeredDeviceModel: registeredDeviceModel ?? this.registeredDeviceModel,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'employeeId': employeeId,
      'fullName': fullName,
      'email': email,
      'department': department,
      'role': role,
      'phone': phone,
      'registeredDeviceId': registeredDeviceId,
      'registeredDeviceModel': registeredDeviceModel,
      'joinedDate': joinedDate.toIso8601String(),
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map, {required String uid}) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        // Firestore Timestamp has toDate(); strings are ISO-8601.
        if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
        return (v as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return EmployeeModel(
      uid: uid,
      employeeId: map['employeeId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? 'Employee',
      email: map['email'] as String? ?? '',
      department: map['department'] as String? ?? '',
      role: map['role'] as String? ?? 'Employee',
      phone: map['phone'] as String?,
      registeredDeviceId: map['registeredDeviceId'] as String?,
      registeredDeviceModel: map['registeredDeviceModel'] as String?,
      joinedDate: parseDate(map['joinedDate'] ?? map['createdAt']),
    );
  }
}
