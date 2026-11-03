import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCcMQ7GmgZE3YrSd1KrrA0ZifWvp2mnwoo',
        appId: '1:950308695939:android:9257385cd7c35b8b6410b6',
        messagingSenderId: '950308695939',
        projectId: 'recipebox-95b1b',
        storageBucket: 'recipebox-95b1b.firebasestorage.app',
      ),
    );
    runApp(const RecipeBoxApp());
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to start RecipeBox. Check your connection and reopen the app.\n$error',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
