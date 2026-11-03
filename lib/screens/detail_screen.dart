import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_repository.dart';
import '../widgets/common.dart';
import '../widgets/recipe_form.dart';
import '../widgets/favorite_button.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.recipe,
    required this.repository,
  });
  final Recipe recipe;
  final RecipeRepository repository;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Recipe current = widget.recipe;
  late final stream = widget.repository.watch();
  bool editing = false, busy = false;
  String? error;
  StreamSubscription<User?>? authSubscription;
  @override
  void initState() {
    super.initState();
    authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted && user?.uid != widget.repository.uid) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    super.dispose();
  }

  Future<void> remove(Recipe r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: const Text(
          'This recipe will be permanently removed from your collection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.repository.delete(r);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = backendMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.uid != widget.repository.uid) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }
    return PopScope(
      canPop: !editing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && editing) setState(() => editing = false);
      },
      child: StreamBuilder<List<Recipe>>(
        stream: stream,
        builder: (context, snapshot) {
          final matches = (snapshot.data ?? []).where(
            (r) => r.id == current.id,
          );
          final r = matches.isNotEmpty ? matches.first : current;
          return Scaffold(
            appBar: AppBar(
              title: Text(editing ? 'Edit recipe' : 'Detail'),
              actions: [
                if (!editing)
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => editing = true),
                    child: const Text('Edit'),
                  ),
              ],
            ),
            body: PageBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null) MessageBanner(error!, error: true),
                  if (snapshot.hasError)
                    MessageBanner(backendMessage(snapshot.error!), error: true),
                  if (editing)
                    RecipeForm(
                      key: ValueKey(r.id),
                      repository: widget.repository,
                      initial: r,
                      onCancel: () => setState(() => editing = false),
                      onSaved: (updated) => setState(() {
                        current = updated;
                        editing = false;
                      }),
                    )
                  else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ),
                            FavoriteButton(
                              recipe: r,
                              repository: widget.repository,
                              onError: (e) {
                                if (mounted) setState(() => error = e);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (final field in [
                      ('Category', r.category),
                      ('Difficulty', r.difficulty),
                      ('Cook time', '${r.cookTime} min'),
                      ('Servings', r.servings?.toString() ?? 'Not specified'),
                      ('Notes', r.notes.isEmpty ? 'No notes' : r.notes),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              field.$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              field.$2,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: busy ? null : () => remove(r),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB42318),
                      ),
                      child: Text(busy ? 'Deleting...' : 'Delete'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
