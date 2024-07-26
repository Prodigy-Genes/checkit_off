// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsernameUpdateDialog extends StatefulWidget {
  final User? user;

  const UsernameUpdateDialog({Key? key, required this.user}) : super(key: key);

  @override
  _UsernameUpdateDialogState createState() => _UsernameUpdateDialogState();
}

class _UsernameUpdateDialogState extends State<UsernameUpdateDialog> {
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.displayName);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Image.asset(
            'assets/images/username.png',
            height: 30,
            width: 30,
          ),
          const SizedBox(width: 10),
          const Text(
            'Update Username',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: TextField(
        controller: _usernameController,
        decoration: const InputDecoration(hintText: 'Enter new username'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          onPressed: () async {
            if (_usernameController.text.isNotEmpty) {
              try {
                String newUsername = _usernameController.text;

                // Update the username in Firebase Auth
                await widget.user?.updateDisplayName(newUsername);

                // Update the username in Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.user!.uid)
                    .update({'username': newUsername});

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Username updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update username: $e')),
                );
              }
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
