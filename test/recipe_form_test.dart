import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipebox/core/theme.dart';
import 'package:recipebox/models/recipe.dart';
import 'package:recipebox/services/recipe_repository.dart';
import 'package:recipebox/widgets/common.dart';
import 'package:recipebox/widgets/recipe_form.dart';

class DatabaseStub extends Fake implements FirebaseFirestore {}

class RecordingRepository extends RecipeRepository {
  RecordingRepository() : super('owner', database: DatabaseStub());
  Recipe? saved;
  @override
  Future<void> save(Recipe recipe, {Recipe? previous}) async {
    saved = recipe;
  }
}

void main() {
  testWidgets(
    'add validation appears only after submit and exact required messages clear',
    (tester) async {
      final repository = RecordingRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          home: Scaffold(
            body: PageBody(child: RecipeForm(repository: repository)),
          ),
        ),
      );
      expect(find.text('Name is required'), findsNothing);
      await tester.ensureVisible(find.text('Add Recipe'));
      await tester.tap(find.text('Add Recipe'));
      await tester.pumpAndSettle();
      for (final message in [
        'Name is required',
        'Please choose a category',
        'Please choose a difficulty',
        'Cook time is required',
      ]) {
        expect(find.text(message), findsOneWidget);
      }
      expect(repository.saved, null);
      await tester.enterText(find.byType(TextFormField).at(0), 'Test soup');
      await tester.pumpAndSettle();
      expect(find.text('Name is required'), findsNothing);
    },
  );
  testWidgets(
    'successful add clears fields and choices without premature errors',
    (tester) async {
      final repository = RecordingRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          home: Scaffold(
            body: PageBody(child: RecipeForm(repository: repository)),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Test soup');
      for (final choice in [(0, 'Lunch'), (1, 'Easy')]) {
        final field = find
            .byType(DropdownButtonFormField<String>)
            .at(choice.$1);
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice.$2).last);
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byType(TextFormField).at(1), '15');
      await tester.ensureVisible(find.text('Add Recipe'));
      await tester.tap(find.text('Add Recipe'));
      await tester.pumpAndSettle();
      expect(repository.saved?.cookTime, 15);
      expect(repository.saved?.servings, null);
      expect(repository.saved?.favorite, false);
      expect(find.text('Recipe added'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text('Name is required'), findsNothing);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>).first,
            )
            .initialValue,
        '',
      );
    },
  );
}
