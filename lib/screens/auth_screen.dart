import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/validation.dart';
import '../services/recipe_repository.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.register,
    required this.onBack,
    required this.onSwitch,
    required this.onRegistration,
  });
  final bool register;
  final VoidCallback onBack, onSwitch;
  final ValueChanged<bool> onRegistration;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final key = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool submitted = false, busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      submitted = true;
      error = null;
    });
    if (!key.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      if (widget.register) {
        widget.onRegistration(true);
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } catch (e) {
      if (widget.register) widget.onRegistration(false);
      if (mounted) setState(() => error = backendMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !busy) widget.onBack();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: busy ? null : widget.onBack),
        title: Text(widget.register ? 'Register' : 'Login'),
      ),
      body: PageBody(
        child: Form(
          key: key,
          autovalidateMode: submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Heading(widget.register ? 'Create your account' : 'Welcome back'),
              Text(
                widget.register
                    ? 'Start your own private recipe collection.'
                    : 'Log in to continue to your recipes.',
              ),
              const SizedBox(height: 32),
              FormFieldBox(
                label: 'Email',
                controller: email,
                validator: Validation.email,
              ),
              FormFieldBox(
                label: 'Password',
                controller: password,
                password: true,
                validator: (v) =>
                    Validation.password(v, register: widget.register),
                onChanged: (_) {
                  if (submitted) key.currentState!.validate();
                },
              ),
              if (widget.register)
                FormFieldBox(
                  label: 'Confirm password',
                  controller: confirm,
                  password: true,
                  validator: (v) => Validation.confirm(v, password.text),
                ),
              FilledButton(
                onPressed: busy ? null : submit,
                child: Text(
                  busy
                      ? 'Signing in...'
                      : widget.register
                      ? 'Register'
                      : 'Login',
                ),
              ),
              if (error != null) MessageBanner(error!, error: true),
              const SizedBox(height: 12),
              TextButton(
                onPressed: busy ? null : widget.onSwitch,
                child: Text(
                  widget.register
                      ? 'Already have an account? Login'
                      : 'Create an account — Register',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
