// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:checkit_off/user_auth/presentation/screens/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleSignin extends StatelessWidget {
  const GoogleSignin({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _signInWithGoogle(context),
      icon: const Icon(Icons.login, color: Colors.black),
      label: const Text('Sign in with Google', style: TextStyle(color: Colors.black)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    try {
      // Attempt to sign in the user.
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        // Obtain the Google Sign-In authentication token.
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        // Create a new credential using the token.
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        // Sign in to Firebase with the Google credential.
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        // If the sign-in was successful, save user data to Firestore.
        if (user != null) {
          await _saveUserDataToFirestore(user);

          // Navigate to the home screen.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } catch (error) {
      // Handle the sign-in error.
      print('Google sign in error: $error');
      _showErrorToast(context, 'Failed to sign in with Google. Please try again.');
    }
  }

  Future<void> _saveUserDataToFirestore(User user) async {
    final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

    // Check if the user document already exists.
    final DocumentSnapshot userDoc = await usersCollection.doc(user.uid).get();

    // If the user document does not exist, create a new one.
    if (!userDoc.exists) {
      await usersCollection.doc(user.uid).set({
        'uid': user.uid,
        'username': user.displayName ?? 'Unknown',
        'email': user.email ?? 'Unknown',
        'profilePictureUrl': user.photoURL ?? '',
        'completedTasks': 0, // Initialize completed tasks to 0 or any default value.
        // Add any additional fields here.
      });
    }
  }

  void _showErrorToast(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
