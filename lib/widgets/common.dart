import 'package:flutter/material.dart';

import '../core/theme.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    ),
  );
}

class MessageBanner extends StatelessWidget {
  const MessageBanner(this.message, {super.key, this.error = false});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFDECEC) : const Color(0xFFEAF5EE),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: error ? const Color(0xFFB42318) : const Color(0xFF245D3D),
      ),
    ),
  );
}

class Heading extends StatelessWidget {
  const Heading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16, top: 8),
    child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
  );
}

class FormFieldBox extends StatelessWidget {
  const FormFieldBox({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.numeric = false,
    this.password = false,
    this.lines = 1,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool numeric, password;
  final int lines;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: password,
          maxLines: lines,
          onChanged: onChanged,
          keyboardType: numeric
              ? TextInputType.number
              : password
              ? TextInputType.visiblePassword
              : label == 'Email'
              ? TextInputType.emailAddress
              : TextInputType.multiline,
          textInputAction: lines > 1
              ? TextInputAction.newline
              : TextInputAction.next,
          decoration: InputDecoration(hintText: label),
        ),
      ],
    ),
  );
}

class ChoiceField extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder,
    this.validator,
  });
  final String label;
  final String? value, placeholder;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          validator: validator,
          items: [
            if (placeholder != null)
              DropdownMenuItem(
                value: '',
                child: Text(placeholder!, style: const TextStyle(color: muted)),
              ),
            ...options.map((s) => DropdownMenuItem(value: s, child: Text(s))),
          ],
          onChanged: onChanged,
        ),
      ],
    ),
  );
}
