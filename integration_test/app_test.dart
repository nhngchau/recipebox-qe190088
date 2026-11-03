import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recipebox/main.dart' as app;
import 'package:recipebox/widgets/recipe_form.dart';
import 'package:recipebox/widgets/favorite_button.dart';
import 'package:recipebox/widgets/common.dart';
import 'package:recipebox/services/recipe_repository.dart';

void main() {
  const testEmail = String.fromEnvironment('TEST_EMAIL');
  const testPassword = String.fromEnvironment('TEST_PASSWORD');
  const isolationEmail = String.fromEnvironment('ISOLATION_EMAIL');
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real Firebase application flows and screenshot evidence', (
    tester,
  ) async {
    expect(
      [testEmail, testPassword, isolationEmail],
      everyElement(isNotEmpty),
      reason: 'Supply TEST_EMAIL, TEST_PASSWORD and ISOLATION_EMAIL with --dart-define.',
    );
    await app.main();
    await tester.pumpAndSettle();
    await FirebaseAuth.instance.signOut();
    await tester.pumpAndSettle();
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          Uri.parse('http://10.0.2.2:18766/$name'),
        );
        final response = await request.close();
        expect(response.statusCode, 200);
        await response.drain<void>();
      } finally {
        client.close(force: true);
      }
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> type(Finder finder, String value) async {
      await tester.ensureVisible(finder);
      await tester.enterText(finder, value);
      await tester.pumpAndSettle();
    }

    Future<void> top() async {
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 4000),
      );
      await tester.pumpAndSettle();
    }

    Future<void> waitFor(Finder f) async {
      for (var i = 0; i < 60 && f.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(f, findsWidgets);
    }

    Future<void> choose(String label, String value) async {
      final f = find
          .ancestor(of: find.text(label), matching: find.byType(Column))
          .first;
      final dropdown = find.descendant(
        of: f,
        matching: find.byType(DropdownButtonFormField<String>),
      );
      await tap(dropdown);
      await tap(find.text(value).last);
    }

    await shot('00_home');
    await tap(find.widgetWithText(TextButton, 'Register').first);
    await tap(find.widgetWithText(FilledButton, 'Register'));
    expect(find.text('Email is required'), findsOneWidget);
    await top();
    await shot('04_register_validation');
    final newEmail =
        'ui.qe190088.${DateTime.now().millisecondsSinceEpoch}@example.com';
    await type(find.byType(TextFormField).at(0), newEmail);
    await type(find.byType(TextFormField).at(1), testPassword);
    await type(find.byType(TextFormField).at(2), testPassword);
    await tap(find.widgetWithText(FilledButton, 'Register'));
    await waitFor(find.text('Registration successful'));
    await top();
    await shot('05_register_success');
    await tap(find.text('Logout'));
    await tap(find.widgetWithText(TextButton, 'Register').first);
    await type(find.byType(TextFormField).at(0), newEmail);
    await type(find.byType(TextFormField).at(1), testPassword);
    await type(find.byType(TextFormField).at(2), testPassword);
    await tap(find.widgetWithText(FilledButton, 'Register'));
    await waitFor(find.byType(MessageBanner));
    expect(
      tester.widget<MessageBanner>(find.byType(MessageBanner)).error,
      true,
    );
    await shot('05b_duplicate_email');
    await tap(find.text('Already have an account? Login'));
    await shot('06_login');
    await type(find.byType(TextFormField).at(0), testEmail);
    await type(find.byType(TextFormField).at(1), testPassword);
    await tap(find.widgetWithText(FilledButton, 'Login'));
    await waitFor(find.text('Logout'));
    final baseline = await RecipeRepository(
      FirebaseAuth.instance.currentUser!.uid,
    ).watch().first;
    expect(baseline.length, greaterThanOrEqualTo(5));
    await waitFor(find.text('Recipes: ${baseline.length}'));
    await shot('07_list_summary');
    expect(Navigator.of(tester.element(find.text('Logout'))).canPop(), false);
    expect(find.text('Logout'), findsOneWidget);
    await tester.ensureVisible(find.text('Garlic Butter Pasta'));
    await shot('07_list_after_login');
    await top();
    await choose('Category filter', 'Dinner');
    expect(
      find.text(
        'Recipes: ${baseline.where((r) => r.category == "Dinner").length}',
      ),
      findsOneWidget,
    );
    await shot('10_category_filter');
    await choose('Difficulty filter', 'Medium');
    expect(
      find.text(
        'Recipes: ${baseline.where((r) => r.category == "Dinner" && r.difficulty == "Medium").length}',
      ),
      findsOneWidget,
    );
    await shot('11_difficulty_filter');
    await tap(find.text('Clear'));
    await tap(find.byType(Switch));
    expect(
      find.text('Recipes: ${baseline.where((r) => r.favorite).length}'),
      findsOneWidget,
    );
    await shot('12_favorites_filter');
    await tap(find.text('Clear'));
    await type(find.byType(TextField).first, '  herbs  ');
    expect(find.text('Recipes: 1'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await shot('13_search');
    await tap(find.text('Clear'));
    await tap(find.widgetWithText(FilledButton, 'Add Recipe'));
    expect(find.text('Name is required'), findsOneWidget);
    await tester.ensureVisible(find.text('Name is required'));
    await shot('08_add_validation');
    final recipeForm = find.byType(RecipeForm);
    final fields = find.descendant(
      of: recipeForm,
      matching: find.byType(TextFormField),
    );
    await type(fields.at(0), 'Emulator Test Soup');
    await choose('Category', 'Lunch');
    await choose('Difficulty', 'Easy');
    await type(fields.at(1), '12');
    await type(fields.at(2), '2');
    await type(fields.at(3), 'Made during the real emulator verification.');
    await tap(find.widgetWithText(FilledButton, 'Add Recipe'));
    await waitFor(find.text('Recipe added'));
    await tester.ensureVisible(find.text('Recipe added'));
    await shot('09_add_success');
    await type(fields.at(0), 'EMULATOR TEST SOUP');
    await choose('Category', 'Lunch');
    await choose('Difficulty', 'Easy');
    await type(fields.at(1), '12');
    await tap(find.widgetWithText(FilledButton, 'Add Recipe'));
    await waitFor(find.text('A recipe with this name already exists.'));
    await tester.ensureVisible(
      find.text('A recipe with this name already exists.'),
    );
    await shot('09b_duplicate_recipe');
    await tap(find.text('Emulator Test Soup'));
    await shot('14_detail_view');
    await tap(find.text('Edit'));
    final editFields = find.descendant(
      of: find.byType(RecipeForm),
      matching: find.byType(TextFormField),
    );
    await type(editFields.at(0), '');
    await tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.ensureVisible(find.text('Name is required'));
    await shot('15_edit_validation');
    await type(editFields.at(0), 'Emulator Test Soup Updated');
    await type(editFields.at(1), '9');
    await tap(find.widgetWithText(FilledButton, 'Save'));
    await waitFor(find.text('Detail'));
    await shot('16_detail_after_save');
    await shot('17_favorite_before');
    await tap(find.byType(FavoriteButton));
    await shot('18_favorite_after');
    await tap(find.widgetWithText(OutlinedButton, 'Delete'));
    await shot('19_delete_confirmation');
    await tap(find.widgetWithText(FilledButton, 'Delete'));
    await waitFor(find.text('Logout'));
    expect(find.text('Emulator Test Soup Updated'), findsNothing);
    await tester.ensureVisible(find.text('Garlic Butter Pasta'));
    await shot('20_delete_after');
    await top();
    await tap(find.text('Logout'));
    await tap(find.widgetWithText(TextButton, 'Login').first);
    await type(find.byType(TextFormField).at(0), isolationEmail);
    await type(find.byType(TextFormField).at(1), testPassword);
    await tap(find.widgetWithText(FilledButton, 'Login'));
    await waitFor(find.text('Recipes: 0'));
    await tester.ensureVisible(find.text('No recipes found'));
    await shot('21_empty_state');
    expect(find.text('Chicken Salad'), findsNothing);
    expect(tester.takeException(), null);
  });
}
