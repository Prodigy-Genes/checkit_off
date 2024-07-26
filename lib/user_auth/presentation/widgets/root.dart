import 'package:checkit_off/user_auth/presentation/screens/home_page.dart';
import 'package:checkit_off/user_auth/presentation/screens/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
     return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const HomePage(); // Navigate to home page if user is authenticated
        }
        return const Login(); // Navigate to login page if user is not authenticated
      },
    );
  }
}