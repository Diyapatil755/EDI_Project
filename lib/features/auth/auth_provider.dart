import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/employee_model.dart';
import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../../services/otp_service.dart';

enum AuthScreenState {
  splash,
  login,
  otpVerification,
  deviceRegistration,
  authenticated,
}

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final OtpService _otpService;
  final DeviceService _deviceService;

  AuthScreenState _state = AuthScreenState.splash;
  bool _isLoading = false;
  String? _errorMessage;
  EmployeeModel? _currentEmployee;
  String? _pendingDestination;
  DeviceMetadata? _currentDeviceMetadata;

  AppAuthProvider(
    this._authService,
    this._otpService,
    this._deviceService,
  ) {
    _checkInitialSession();
  }

  AuthScreenState get state => _state;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  EmployeeModel? get currentEmployee => _currentEmployee;
  DeviceMetadata? get currentDeviceMetadata => _currentDeviceMetadata;

  /// Signs out and returns to login with a message.
  Future<void> _forceLogin(String message) async {
    await _authService.signOut();
    _currentEmployee = null;
    _errorMessage = message;
    _state = AuthScreenState.login;
    _isLoading = false;
    notifyListeners();
  }

  /// True when the account is bound to a different phone than this one.
  bool _isOtherDevice(EmployeeModel e, DeviceMetadata d) =>
      e.hasRegisteredDevice && e.registeredDeviceId != d.deviceId;

  Future<void> _checkInitialSession() async {
    _state = AuthScreenState.splash;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    // Not signed in -> login.
    if (_authService.currentUid == null) {
      _state = AuthScreenState.login;
      notifyListeners();
      return;
    }

    try {
      final device = await _deviceService.getDeviceMetadata();
      final employee = await _authService.getCurrentEmployee();
      _currentDeviceMetadata = device;

      if (_isOtherDevice(employee, device)) {
        await _forceLogin(AppConstants.msgDeviceMismatch);
        return;
      }

      final verified = await _authService.isSessionVerified();
      if (employee.hasRegisteredDevice && verified) {
        _currentEmployee = employee;
        _state = AuthScreenState.authenticated;
        notifyListeners();
        return;
      }

      // Signed in but never finished OTP / device step -> start again.
      await _forceLogin('Please sign in again.');
    } on EmployeeProfileMissing {
      await _forceLogin(AppConstants.msgProfileMissing);
    } catch (_) {
      // Most likely offline: keep the person on login instead of guessing.
      _state = AuthScreenState.login;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signIn(
      identifier: identifier,
      password: password,
    );

    if (!result.isSuccess) {
      _isLoading = false;
      _errorMessage = result.errorMessage ?? 'Invalid employee ID or password';
      notifyListeners();
      return false;
    }

    try {
      final employee = await _authService.getCurrentEmployee();
      final device = await _deviceService.getDeviceMetadata();
      _currentDeviceMetadata = device;

      // One account = one phone. Checked BEFORE sending any OTP.
      if (_isOtherDevice(employee, device)) {
        await _forceLogin(AppConstants.msgDeviceMismatch);
        return false;
      }

      final destination = employee.phone ?? '';
      if (AppConstants.useRealOtp && destination.isEmpty) {
        await _forceLogin(
          'No phone number is registered for your account. Contact your administrator.',
        );
        return false;
      }

      final sent = await _otpService.sendOtp(destination: destination);
      if (!sent) {
        await _forceLogin('Could not send OTP. Check your number and try again.');
        return false;
      }

      _currentEmployee = employee;
      _pendingDestination = destination;
      _isLoading = false;
      _state = AuthScreenState.otpVerification;
      notifyListeners();
      return true;
    } on EmployeeProfileMissing {
      await _forceLogin(AppConstants.msgProfileMissing);
      return false;
    } catch (_) {
      await _forceLogin('Something went wrong. Please try again.');
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final isValid = await _otpService.verifyOtp(code: code);

    if (!isValid) {
      _isLoading = false;
      _errorMessage =
          'Invalid 6-digit verification code. Please check and try again.';
      notifyListeners();
      return false;
    }

    try {
      final employee = await _authService.getCurrentEmployee();
      final device = await _deviceService.getDeviceMetadata();
      _currentDeviceMetadata = device;

      if (_isOtherDevice(employee, device)) {
        await _forceLogin(AppConstants.msgDeviceMismatch);
        return false;
      }

      if (AppConstants.useRealOtp) {
        await _authService.markPhoneVerified();
      }
      await _authService.setSessionVerified(true);

      _currentEmployee = employee;
      _state = employee.hasRegisteredDevice
          ? AuthScreenState.authenticated
          : AuthScreenState.deviceRegistration;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      await _forceLogin('Something went wrong. Please sign in again.');
      return false;
    }
  }

  Future<bool> resendOtp() async {
    if (_pendingDestination == null) return false;
    _isLoading = true;
    notifyListeners();
    final res = await _otpService.sendOtp(destination: _pendingDestination!);
    _isLoading = false;
    notifyListeners();
    return res;
  }

  Future<void> registerCurrentDevice() async {
    _isLoading = true;
    notifyListeners();

    try {
      final device = await _deviceService.getDeviceMetadata();
      await _authService.updateRegisteredDevice(
        deviceId: device.deviceId,
        deviceModel: device.modelName,
      );
      await _deviceService.bindDeviceAsRegistered(deviceId: device.deviceId);

      _currentEmployee = await _authService.getCurrentEmployee();
      _state = AuthScreenState.authenticated;
      _isLoading = false;
      notifyListeners();
    } on StateError {
      // Someone registered another phone in the meantime.
      await _forceLogin(AppConstants.msgDeviceMismatch);
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Could not register this device. Check internet and retry.';
      notifyListeners();
    }
  }

  Future<void> requestPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentEmployee = null;
    _errorMessage = null;
    _state = AuthScreenState.login;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
