import 'package:flutter_test/flutter_test.dart';
import 'package:recipebox/core/validation.dart';
import 'package:recipebox/models/recipe.dart';

Recipe recipe(
  String name,
  int time,
  String category, {
  bool favorite = false,
  String notes = '',
}) => Recipe(
  id: recipeId('user', name),
  userId: 'user',
  name: name,
  category: category,
  difficulty: 'Easy',
  cookTime: time,
  favorite: favorite,
  notes: notes,
);
void main() {
  test('exact auth validation and password rules', () {
    expect(Validation.email('  '), 'Email is required');
    expect(Validation.email('invalid'), 'Please enter a valid email address');
    expect(Validation.email(' a@b.com '), null);
    expect(Validation.password(''), 'Password is required');
    expect(
      Validation.password('12345', register: true),
      'Password must be at least 6 characters',
    );
    expect(Validation.password('a'), null);
    expect(Validation.confirm('', 'secret'), 'Confirm password is required');
    expect(Validation.confirm('other', 'secret'), 'Passwords do not match');
    expect(Validation.confirm('secret', 'secret'), null);
  });
  test('recipe field boundaries and exact errors', () {
    expect(Validation.name('   '), 'Name is required');
    expect(Validation.name('a' * 81), 'Name must be at most 80 characters');
    expect(Validation.name('a' * 80), null);
    expect(Validation.cookTime(''), 'Cook time is required');
    for (final invalid in ['0', '601', '1.5', 'abc', '-1']) {
      expect(
        Validation.cookTime(invalid),
        'Cook time must be a whole number from 1 to 600',
      );
    }
    for (final valid in ['1', '600', ' 25 ']) {
      expect(Validation.cookTime(valid), null);
    }
    expect(Validation.servings(''), null);
    expect(Validation.servings('20'), null);
    for (final invalid in ['0', '21', '2.5']) {
      expect(
        Validation.servings(invalid),
        'Servings must be a whole number from 1 to 20',
      );
    }
    expect(Validation.notes('x' * 300), null);
    expect(Validation.notes('x' * 301), 'Notes must be at most 300 characters');
  });
  test('sort by cook time then insensitive name; combine all filters', () {
    final all = [
      recipe('Zebra', 10, 'Dinner', favorite: true, notes: 'Fresh HERBS'),
      recipe('apple', 10, 'Breakfast'),
      recipe('Fast', 5, 'Dinner', favorite: true),
      recipe('Slow', 60, 'Dinner'),
    ];
    expect(visibleRecipes(all).map((r) => r.name), [
      'Fast',
      'apple',
      'Zebra',
      'Slow',
    ]);
    final filtered = visibleRecipes(
      all,
      category: 'Dinner',
      difficulty: 'Easy',
      favoritesOnly: true,
      search: '  herbs  ',
    );
    expect(filtered.single.name, 'Zebra');
    expect(filtered.fold<int>(0, (n, r) => n + r.cookTime), 10);
    expect(visibleRecipes(all, category: 'Dessert'), isEmpty);
  });
  test('category breakdown count descending, prescribed ties', () {
    final all = [
      recipe('a', 1, 'Dinner'),
      recipe('b', 1, 'Dinner'),
      recipe('c', 1, 'Dessert'),
      recipe('d', 1, 'Breakfast'),
      recipe('e', 1, 'Lunch'),
    ];
    expect(categoryCounts(all).map((e) => e.key), [
      'Dinner',
      'Breakfast',
      'Lunch',
      'Dessert',
    ]);
  });
  test(
    'canonical IDs isolate owners, support Unicode and slash, ignore case',
    () {
      expect(recipeId('a', ' Pho Bo '), recipeId('a', 'pho bo'));
      expect(recipeId('a', 'pho'), isNot(recipeId('b', 'pho')));
      expect(recipeId('a', 'Cơm / Rice').contains('/'), false);
      expect(recipeId('a', 'Pho'), 'a_70686F');
    },
  );
}
