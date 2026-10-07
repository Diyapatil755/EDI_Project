import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/device_registration_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/otp_verification_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/face/face_attendance_provider.dart';
import 'features/history/history_provider.dart';
import 'features/home/home_provider.dart';
import 'features/main_shell.dart';
import 'firebase_options.dart';
import 'services/attendance_repository.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/device_service.dart';
import 'services/face_liveness_service.dart';
import 'services/ledger_service.dart';
import 'services/location_service.dart';
import 'services/otp_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartAttendanceApp());
}

class SmartAttendanceApp extends StatelessWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Core service singletons
    final authService = FirebaseAuthService();
    final OtpService otpService =
        AppConstants.useRealOtp ? FirebasePhoneOtpService() : MockOtpService();
    final deviceService = AppDeviceService();
    final locationService = GeoLocationService();
    final faceService = CameraMlKitFaceLivenessService();
    final ledgerService = MockLedgerService();
    final connectivityService = AppConnectivityService();
    final attendanceRepo = FirebaseAttendanceRepository(
      ledgerService: ledgerService,
    );

    return MultiProvider(
      providers: [
        // Service Providers
        Provider<AuthService>.value(value: authService),
        Provider<OtpService>.value(value: otpService),
        Provider<DeviceService>.value(value: deviceService),
        Provider<LocationService>.value(value: locationService),
        Provider<FaceLivenessService>.value(value: faceService),
        Provider<LedgerService>.value(value: ledgerService),
        Provider<AttendanceRepository>.value(value: attendanceRepo),
        Provider<ConnectivityService>.value(value: connectivityService),

        // Feature State Notifiers
        ChangeNotifierProvider(
          create: (_) => AppAuthProvider(
            authService,
            otpService,
            deviceService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeProvider(
            attendanceRepo,
            locationService,
            connectivityService,
            deviceService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FaceAttendanceProvider(
            faceService,
            authService,
            locationService,
            deviceService,
            attendanceRepo,
            connectivityService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(
            attendanceRepo,
            ledgerService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Attendance System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthFlowCoordinator(),
      ),
    );
  }
}

class AuthFlowCoordinator extends StatelessWidget {
  const AuthFlowCoordinator({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    switch (auth.state) {
      case AuthScreenState.splash:
        return const SplashScreen();
      case AuthScreenState.login:
        return const LoginScreen();
      case AuthScreenState.otpVerification:
        return const OtpVerificationScreen();
      case AuthScreenState.deviceRegistration:
        return const DeviceRegistrationScreen();
      case AuthScreenState.authenticated:
        return const MainShell();
    }
  }
}