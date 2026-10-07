import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/employee_model.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? uid;
  final String? idToken;

  const AuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.uid,
    this.idToken,
  });
}

abstract class AuthService {
  /// Emits the signed-in uid, or null when signed out.
  Stream<String?> get authStateChanges;
  String? get currentUid;
  String? get currentEmail;
  Future<String?> getIdToken({bool forceRefresh = false});
  Future<AuthResult> signIn({
    required String identifier,
    required String password,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();

  /// Loads the signed-in employee's profile from Firestore.
  /// Throws [EmployeeProfileMissing] if the account has no profile.
  Future<EmployeeModel> getCurrentEmployee();

  /// Binds a device to the account. Only succeeds if no device is bound yet
  /// (or the same device is bound again).
  Future<void> updateRegisteredDevice({
    required String deviceId,
    required String deviceModel,
  });

  Future<void> markPhoneVerified();

  /// True if this signed-in session already passed OTP on this device.
  /// Stops "kill the app on the OTP screen, reopen, skip OTP".
  Future<bool> isSessionVerified();
  Future<void> setSessionVerified(bool verified);
}

class EmployeeProfileMissing implements Exception {
  @override
  String toString() =>
      'No employee profile found for this account. Contact your administrator.';
}

/// Real Firebase implementation.
/// - Identity comes only from the Firebase ID token (server reads the uid
///   from the verified token, the app never sends an employee id as truth).
/// - Employee profile + bound device live in Firestore: employees/{uid}.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _verifiedKey = 'session_verified_uid';

  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _employeeRef(String uid) =>
      _db.collection(AppConstants.employeesCollection).doc(uid);

  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((u) => u?.uid);

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  @override
  Future<AuthResult> signIn({
    required String identifier,
    required String password,
  }) async {
    final id = identifier.trim();
    // Employee ID (EMP-0417) is mapped to its company email.
    final email = id.contains('@')
        ? id
        : '${id.toLowerCase()}@${AppConstants.employeeEmailDomain}';

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password.trim(),
      );
      final token = await cred.user?.getIdToken();
      return AuthResult(
        isSuccess: true,
        uid: cred.user?.uid,
        idToken: token,
      );
    } on FirebaseAuthException catch (e) {
      // Same message for wrong id / wrong password, so nobody can probe
      // which employee ids exist.
      switch (e.code) {
        case 'network-request-failed':
          return const AuthResult(
            isSuccess: false,
            errorMessage: 'No internet connection. Please try again.',
          );
        case 'too-many-requests':
          return const AuthResult(
            isSuccess: false,
            errorMessage: 'Too many attempts. Please try again later.',
          );
        default:
          return const AuthResult(
            isSuccess: false,
            errorMessage: 'Invalid employee ID or password',
          );
      }
    } catch (_) {
      return const AuthResult(
        isSuccess: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (_) {
      // Do not reveal whether the email exists.
    }
  }

  @override
  Future<void> signOut() async {
    await setSessionVerified(false);
    await _auth.signOut();
  }

  @override
  Future<bool> isSessionVerified() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      return await _storage.read(key: _verifiedKey) == uid;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setSessionVerified(bool verified) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (verified && uid != null) {
        await _storage.write(key: _verifiedKey, value: uid);
      } else {
        await _storage.delete(key: _verifiedKey);
      }
    } catch (_) {}
  }

  @override
  Future<EmployeeModel> getCurrentEmployee() async {
    final user = _auth.currentUser;
    if (user == null) throw EmployeeProfileMissing();

    final ref = _employeeRef(user.uid);
    var snap = await ref.get();

    if (!snap.exists) {
      if (!AppConstants.autoCreateEmployeeProfile) {
        throw EmployeeProfileMissing();
      }
      // Demo convenience: create a basic profile on first login.
      // Turn AppConstants.autoCreateEmployeeProfile off in production and
      // let the admin panel create employees instead.
      final email = user.email ?? '';
      final prefix = email.contains('@') ? email.split('@').first : email;
      await ref.set({
        'employeeId': prefix.toUpperCase(),
        'fullName': prefix,
        'email': email,
        'department': 'Not set',
        'role': 'Employee',
        'createdAt': FieldValue.serverTimestamp(),
      });
      snap = await ref.get();
    }

    return EmployeeModel.fromMap(snap.data() ?? {}, uid: user.uid);
  }

  @override
  Future<void> updateRegisteredDevice({
    required String deviceId,
    required String deviceModel,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw EmployeeProfileMissing();
    final ref = _employeeRef(user.uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final bound = snap.data()?['registeredDeviceId'] as String?;
      if (bound != null && bound.isNotEmpty && bound != deviceId) {
        throw StateError('Another device is already registered.');
      }
      tx.set(
        ref,
        {
          'registeredDeviceId': deviceId,
          'registeredDeviceModel': deviceModel,
          'deviceBoundAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> markPhoneVerified() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _employeeRef(user.uid)
        .set({'phoneVerified': true}, SetOptions(merge: true));
  }
}
