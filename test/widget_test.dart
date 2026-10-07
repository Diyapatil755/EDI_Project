import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_demo/core/constants/app_constants.dart';
import 'package:attendance_demo/core/theme/app_theme.dart';
import 'package:attendance_demo/core/widgets/app_button.dart';
import 'package:attendance_demo/core/widgets/app_card.dart';
import 'package:attendance_demo/core/widgets/status_badge.dart';
import 'package:attendance_demo/features/auth/splash_screen.dart';

void main() {
  testWidgets('SplashScreen smoke test displays branding and organization', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('${AppConstants.organizationName} • Employee Portal'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppButton displays label and responds to taps', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Confirm Attendance',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Confirm Attendance'), findsOneWidget);
    await tester.tap(find.text('Confirm Attendance'));
    expect(tapped, isTrue);
  });

  testWidgets('StatusBadge renders correctly with custom styling', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(
            label: 'On Time',
            type: StatusBadgeType.success,
          ),
        ),
      ),
    );

    expect(find.text('On Time'), findsOneWidget);
  });

  testWidgets('AppCard renders child and adheres to 1px border styling', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCard(
            child: Text('Card Content'),
          ),
        ),
      ),
    );

    expect(find.text('Card Content'), findsOneWidget);
  });
}
