import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract class OtpService {
  int get resendTimeoutSeconds;

  /// [destination] is the employee's registered phone number (E.164).
  Future<bool> sendOtp({required String destination});
  Future<bool> verifyOtp({required String code});
}

/// Real SMS OTP using Firebase Phone Auth.
/// The phone is linked to the signed-in account the first time, and the OTP
/// is re-verified on every later login.
///
/// Needs (Firebase Console): Authentication -> Sign-in method -> Phone ON,
/// and the Android SHA-1 / SHA-256 added to the app. Not supported on
/// Windows desktop.
class FirebasePhoneOtpService implements OtpService {
  final FirebaseAuth _auth;
  String? _verificationId;
  int? _resendToken;

  @override
  final int resendTimeoutSeconds;

  FirebasePhoneOtpService({FirebaseAuth? auth, this.resendTimeoutSeconds = 45})
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<bool> sendOtp({required String destination}) async {
    final completer = Completer<bool>();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: destination.trim(),
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (_) {},
        verificationFailed: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (id, token) {
          _verificationId = id;
          _resendToken = token;
          if (!completer.isCompleted) completer.complete(true);
        },
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
      );
    } catch (_) {
      return false;
    }
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => false,
    );
  }

  @override
  Future<bool> verifyOtp({required String code}) async {
    final id = _verificationId;
    final user = _auth.currentUser;
    if (id == null || user == null) return false;

    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: code.trim(),
      );
      final alreadyLinked =
          user.providerData.any((p) => p.providerId == 'phone');
      if (alreadyLinked) {
        // Checks the code AND that it belongs to the linked phone number.
        await user.reauthenticateWithCredential(cred);
      } else {
        await user.linkWithCredential(cred);
      }
      return true;
    } on FirebaseAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// Development-only OTP. Never ships: in release builds nothing is accepted.
/// Real OTP is turned on with AppConstants.useRealOtp.
class MockOtpService implements OtpService {
  @override
  final int resendTimeoutSeconds;

  MockOtpService({this.resendTimeoutSeconds = 45});

  @override
  Future<bool> sendOtp({required String destination}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }

  @override
  Future<bool> verifyOtp({required String code}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (kReleaseMode) return false;
    final c = code.trim();
    return c == '417892' || c == '123456';
  }
}
