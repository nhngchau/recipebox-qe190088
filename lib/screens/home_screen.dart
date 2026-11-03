import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });
  final VoidCallback onLogin, onRegister;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('RecipeBox'),
      actions: [
        TextButton(onPressed: onLogin, child: const Text('Login')),
        TextButton(onPressed: onRegister, child: const Text('Register')),
      ],
    ),
    body: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.menu_book_rounded, size: 36, color: forest),
          ),
          const SizedBox(height: 24),
          Text('RecipeBox', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 12),
          const Text(
            'Your recipes, all in one place.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Keep a private collection of the meals you love and the dishes you want to try. Find just the right recipe for today.',
            style: TextStyle(color: muted, fontSize: 16),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onRegister, child: const Text('Register')),
          const SizedBox(height: 24),
          for (final feature in [
            (
              Icons.bookmark_outline,
              'Save your recipes',
              'Keep your personal collection organized and private.',
            ),
            (
              Icons.schedule_rounded,
              'Sort by cooking time',
              'Find something that fits the time you have.',
            ),
            (
              Icons.star_border_rounded,
              'Mark your favorites',
              'Keep the recipes you love close at hand.',
            ),
          ])
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(feature.$1, color: forest),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.$2,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature.$3,
                            style: const TextStyle(color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
