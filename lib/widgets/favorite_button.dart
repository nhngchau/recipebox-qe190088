import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_repository.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.recipe,
    required this.repository,
    required this.onError,
  });
  final Recipe recipe;
  final RecipeRepository repository;
  final ValueChanged<String> onError;
  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: widget.recipe.favorite,
    child: IconButton(
      tooltip: widget.recipe.favorite
          ? 'Remove from favorites'
          : 'Mark as favorite',
      onPressed: busy
          ? null
          : () async {
              setState(() => busy = true);
              try {
                await widget.repository.favorite(widget.recipe);
              } catch (e) {
                widget.onError(backendMessage(e));
              } finally {
                if (mounted) setState(() => busy = false);
              }
            },
      icon: Icon(
        widget.recipe.favorite ? Icons.star_rounded : Icons.star_border_rounded,
        color: widget.recipe.favorite
            ? const Color(0xFFD98324)
            : const Color(0xFF9AA29C),
      ),
    ),
  );
}
