import 'package:flutter/material.dart';

import '../core/validation.dart';
import '../models/recipe.dart';
import '../services/recipe_repository.dart';
import 'common.dart';

class RecipeForm extends StatefulWidget {
  const RecipeForm({
    super.key,
    required this.repository,
    this.initial,
    this.onSaved,
    this.onCancel,
  });
  final RecipeRepository repository;
  final Recipe? initial;
  final ValueChanged<Recipe>? onSaved;
  final VoidCallback? onCancel;
  @override
  State<RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<RecipeForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      time = TextEditingController(),
      servings = TextEditingController(),
      notes = TextEditingController();
  String category = '', difficulty = '';
  String? error;
  bool submitted = false, busy = false, success = false;
  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    if (r != null) {
      name.text = r.name;
      time.text = '${r.cookTime}';
      servings.text = r.servings?.toString() ?? '';
      notes.text = r.notes;
      category = r.category;
      difficulty = r.difficulty;
    }
  }

  @override
  void dispose() {
    name.dispose();
    time.dispose();
    servings.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      submitted = true;
      error = null;
      success = false;
    });
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    final r = Recipe(
      id: recipeId(widget.repository.uid, name.text),
      userId: widget.repository.uid,
      name: name.text.trim(),
      category: category,
      difficulty: difficulty,
      cookTime: int.parse(time.text.trim()),
      servings: int.tryParse(servings.text.trim()),
      notes: notes.text,
      favorite: widget.initial?.favorite ?? false,
      createdAt: widget.initial?.createdAt,
    );
    try {
      await widget.repository.save(r, previous: widget.initial);
      if (!mounted) return;
      if (widget.initial == null) {
        form.currentState!.reset();
        name.clear();
        time.clear();
        servings.clear();
        notes.clear();
        setState(() {
          category = '';
          difficulty = '';
          submitted = false;
          success = true;
        });
      }
      widget.onSaved?.call(r);
    } catch (e) {
      if (mounted) setState(() => error = backendMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    autovalidateMode: submitted
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormFieldBox(
          label: 'Name',
          controller: name,
          validator: Validation.name,
        ),
        ChoiceField(
          label: 'Category',
          value: category,
          options: categories,
          placeholder: 'Choose category',
          validator: (v) =>
              v == null || v.isEmpty ? 'Please choose a category' : null,
          onChanged: (v) => setState(() => category = v ?? ''),
        ),
        ChoiceField(
          label: 'Difficulty',
          value: difficulty,
          options: difficulties,
          placeholder: 'Choose difficulty',
          validator: (v) =>
              v == null || v.isEmpty ? 'Please choose a difficulty' : null,
          onChanged: (v) => setState(() => difficulty = v ?? ''),
        ),
        FormFieldBox(
          label: 'Cook time (minutes)',
          controller: time,
          numeric: true,
          validator: Validation.cookTime,
        ),
        FormFieldBox(
          label: 'Servings (optional)',
          controller: servings,
          numeric: true,
          validator: Validation.servings,
        ),
        FormFieldBox(
          label: 'Notes (optional)',
          controller: notes,
          lines: 3,
          validator: Validation.notes,
        ),
        if (widget.onCancel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              onPressed: busy ? null : widget.onCancel,
              child: const Text('Cancel'),
            ),
          ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(
            busy
                ? 'Saving...'
                : widget.initial == null
                ? 'Add Recipe'
                : 'Save',
          ),
        ),
        if (error != null) MessageBanner(error!, error: true),
        if (success) const MessageBanner('Recipe added'),
      ],
    ),
  );
}
