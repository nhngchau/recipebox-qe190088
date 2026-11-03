import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/list_screen.dart';

class RecipeBoxApp extends StatelessWidget {
  const RecipeBoxApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RecipeBox',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: const SessionGate(),
  );
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final stream = FirebaseAuth.instance.authStateChanges();
  String? form;
  bool registration = false;
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: Text('Unable to check sign-in: ${snapshot.error}'),
          ),
        );
      }
      final user = snapshot.data;
      if (user != null) {
        return ListScreen(
          key: ValueKey(user.uid),
          user: user,
          registered: registration,
          onLogout: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              setState(() {
                form = null;
                registration = false;
              });
            }
          },
        );
      }
      if (form != null) {
        return AuthScreen(
          key: ValueKey(form),
          register: form == 'Register',
          onBack: () => setState(() => form = null),
          onSwitch: () =>
              setState(() => form = form == 'Register' ? 'Login' : 'Register'),
          onRegistration: (value) {
            registration = value;
          },
        );
      }
      return HomeScreen(
        onLogin: () => setState(() => form = 'Login'),
        onRegister: () => setState(() => form = 'Register'),
      );
    },
  );
}
