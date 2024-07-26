import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Signout extends StatelessWidget {
  const Signout({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      color: Colors.white,
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        // ignore: use_build_context_synchronously
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        Fluttertoast.showToast(
          msg: "Signed out successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      },
    );
  }
}
