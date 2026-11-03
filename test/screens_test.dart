import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipebox/core/theme.dart';
import 'package:recipebox/screens/auth_screen.dart';
import 'package:recipebox/screens/home_screen.dart';

void main() {
  testWidgets(
    'register has no initial errors; submit shows exact errors and correction clears',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          home: AuthScreen(
            register: true,
            onBack: () {},
            onSwitch: () {},
            onRegistration: (_) {},
          ),
        ),
      );
      expect(find.text('Email is required'), findsNothing);
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Register'));
      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Confirm password is required'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'person@example.com',
      );
      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsNothing);
      await tester.enterText(find.byType(TextFormField).at(1), 'abcdef');
      await tester.enterText(find.byType(TextFormField).at(2), 'abcdef');
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsNothing);
    },
  );
  testWidgets('home works at narrow phone size with required features', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: HomeScreen(onLogin: () {}, onRegister: () {}),
      ),
    );
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Save your recipes'), findsOneWidget);
    expect(find.text('Sort by cooking time'), findsOneWidget);
    expect(find.text('Mark your favorites'), findsOneWidget);
    expect(tester.takeException(), null);
  });
}
