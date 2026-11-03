import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/validation.dart';
import '../models/recipe.dart';
import '../services/recipe_repository.dart';
import '../widgets/common.dart';
import '../widgets/recipe_form.dart';
import '../widgets/favorite_button.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
    required this.user,
    required this.onLogout,
    this.registered = false,
  });
  final User user;
  final Future<void> Function() onLogout;
  final bool registered;
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late final repository = RecipeRepository(widget.user.uid);
  late Stream<List<Recipe>> stream = repository.watch();
  final search = TextEditingController();
  String category = 'All', difficulty = 'All';
  bool favorites = false, loggingOut = false;
  String? error;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void showError(String e) {
    if (mounted) setState(() => error = e);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RecipeBox'),
          Text(
            widget.user.email ?? '',
            style: const TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: loggingOut
              ? null
              : () async {
                  setState(() => loggingOut = true);
                  try {
                    await widget.onLogout();
                  } catch (e) {
                    if (mounted) {
                      setState(() => loggingOut = false);
                      showError(backendMessage(e));
                    }
                  }
                },
          child: const Text('Logout'),
        ),
      ],
    ),
    body: PageBody(
      child: StreamBuilder<List<Recipe>>(
        stream: stream,
        builder: (context, snapshot) {
          final visible = visibleRecipes(
            snapshot.data ?? [],
            category: category,
            difficulty: difficulty,
            favoritesOnly: favorites,
            search: search.text,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.registered)
                const MessageBanner('Registration successful'),
              const Heading('List'),
              TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Search recipes',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 16),
              ChoiceField(
                key: ValueKey('category-$category'),
                label: 'Category filter',
                value: category,
                options: ['All', ...categories],
                onChanged: (v) => setState(() => category = v ?? 'All'),
              ),
              ChoiceField(
                key: ValueKey('difficulty-$difficulty'),
                label: 'Difficulty filter',
                value: difficulty,
                options: ['All', ...difficulties],
                onChanged: (v) => setState(() => difficulty = v ?? 'All'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Favorites only'),
                value: favorites,
                onChanged: (v) => setState(() => favorites = v),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    search.clear();
                    setState(() {
                      category = 'All';
                      difficulty = 'All';
                      favorites = false;
                    });
                  },
                  child: const Text('Clear'),
                ),
              ),
              if (error != null) MessageBanner(error!, error: true),
              if (snapshot.hasError) ...[
                MessageBanner(backendMessage(snapshot.error!), error: true),
                OutlinedButton(
                  onPressed: () => setState(() => stream = repository.watch()),
                  child: const Text('Retry'),
                ),
              ] else if (!snapshot.hasData)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Heading('Summary'),
                        Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          children: [
                            Text('Recipes: ${visible.length}'),
                            Text(
                              'Favorites: ${visible.where((r) => r.favorite).length}',
                            ),
                            Text(
                              'Total time: ${visible.fold<int>(0, (n, r) => n + r.cookTime)} min',
                            ),
                          ],
                        ),
                        if (visible.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Category breakdown',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          for (final c in categoryCounts(visible))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text(c.key)),
                                  Text('${c.value}'),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Heading('Add a recipe'),
                      RecipeForm(repository: repository),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Heading('Your recipes'),
              if (snapshot.hasData && !snapshot.hasError && visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.menu_book_outlined, size: 48, color: muted),
                      SizedBox(height: 12),
                      Text(
                        'No recipes found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try changing your filters or add your first recipe.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              if (!snapshot.hasError)
                for (final r in visible)
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              DetailScreen(recipe: r, repository: repository),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${r.category} · ${r.difficulty}',
                                    style: const TextStyle(color: muted),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('${r.cookTime} min'),
                                ],
                              ),
                            ),
                            FavoriteButton(
                              recipe: r,
                              repository: repository,
                              onError: showError,
                            ),
                            const Icon(Icons.chevron_right, color: muted),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    ),
  );
}
