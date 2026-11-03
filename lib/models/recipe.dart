import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/validation.dart';

// Rules enforce the same collision-free UTF-8 hex ID, including names with '/'.
String recipeId(String uid, String name) =>
    '${uid}_${utf8.encode(name.trim().toLowerCase()).map((b) => b.toRadixString(16).padLeft(2, '0')).join('').toUpperCase()}';

class Recipe {
  const Recipe({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.cookTime,
    this.servings,
    this.favorite = false,
    this.notes = '',
    this.createdAt,
  });
  final String id, userId, name, category, difficulty, notes;
  final int cookTime;
  final int? servings;
  final bool favorite;
  final Timestamp? createdAt;
  factory Recipe.fromMap(Map<String, dynamic> d) => Recipe(
    id: d['id'] as String,
    userId: d['userId'] as String,
    name: d['name'] as String,
    category: d['category'] as String,
    difficulty: d['difficulty'] as String,
    cookTime: d['cookTime'] as int,
    servings: d['servings'] as int?,
    favorite: d['favorite'] as bool,
    notes: d['notes'] as String? ?? '',
    createdAt: d['createdAt'] as Timestamp?,
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'category': category,
    'difficulty': difficulty,
    'cookTime': cookTime,
    if (servings != null) 'servings': servings,
    'favorite': favorite,
    'notes': notes,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };
}

List<Recipe> visibleRecipes(
  List<Recipe> all, {
  String category = 'All',
  String difficulty = 'All',
  bool favoritesOnly = false,
  String search = '',
}) {
  final query = search.trim().toLowerCase();
  return all
      .where(
        (r) =>
            (category == 'All' || r.category == category) &&
            (difficulty == 'All' || r.difficulty == difficulty) &&
            (!favoritesOnly || r.favorite) &&
            (r.name.toLowerCase().contains(query) ||
                r.notes.toLowerCase().contains(query)),
      )
      .toList()
    ..sort((a, b) {
      final time = a.cookTime.compareTo(b.cookTime);
      return time != 0
          ? time
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
}

List<MapEntry<String, int>> categoryCounts(List<Recipe> recipes) {
  final counts = <String, int>{};
  for (final r in recipes) {
    counts.update(r.category, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts.entries.toList()..sort((a, b) {
    final n = b.value.compareTo(a.value);
    return n != 0
        ? n
        : categories.indexOf(a.key).compareTo(categories.indexOf(b.key));
  });
}
