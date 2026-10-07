import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_banner.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import 'auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _countdownTimer;
  int _secondsRemaining = 45;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = 45);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _submitOtp() {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits of the verification code')),
      );
      return;
    }
    context.read<AppAuthProvider>().verifyOtp(code);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Two-Factor Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: auth.logout,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueTint,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Verify Identity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  const Text(
                    'Enter the 6-digit one-time code sent to your registered work credentials.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (auth.errorMessage != null) ...[
                    AppBanner(
                      type: AppBannerType.error,
                      title: 'Invalid Code',
                      message: auth.errorMessage!,
                      onAction: auth.clearError,
                      actionLabel: 'Dismiss',
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '6-Digit Verification Code',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 10,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: '000000',
                            hintStyle: TextStyle(
                              letterSpacing: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _secondsRemaining > 0
                                  ? 'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}'
                                  : 'Code expired',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: _secondsRemaining == 0
                                  ? () {
                                      auth.resendOtp();
                                      _startCountdown();
                                    }
                                  : null,
                              child: const Text('Resend Code'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Verify and Continue',
                          onPressed: _submitOtp,
                          isLoading: auth.isLoading,
                        ),
                      ],
                    ),
                  ),
                  if (!AppConstants.useRealOtp) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueTint,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.primaryBlue),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Demo PIN: Use standard code 417892 (or 123456)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
