// ignore_for_file: use_build_context_synchronously

import 'package:checkit_off/global/models/user.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatelessWidget {
  final UserModel user;

  const UserProfileScreen({Key? key, required this.user}) : super(key: key);

  Future<int> getCompletedTasksCount(String userId) async {
    final completedTasksCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('completed_tasks');

    final snapshot = await completedTasksCollection.get();
    return snapshot.size; // Returns the number of documents in the collection
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      backgroundColor: Colors.grey[900],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.32,
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<int>(
          future: getCompletedTasksCount(user.uid), // Fetch completed tasks count
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final completedTasksCount = snapshot.data ?? 0; // Get the count

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 102, 0),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const Divider(color: Colors.white),
                Text(
                  'Username: ${user.username}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
                ),
                Text(
                  'Email: ${user.email}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
                ),
                Text(
                  'Completed Tasks: $completedTasksCount', // Display the count
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _sendCollaborationRequest(context, user.uid);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color.fromARGB(255, 111, 110, 110),
                      backgroundColor: const Color.fromARGB(255, 252, 157, 5),
                    ),
                    child: const Text('Initiate Collaboration'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _sendCollaborationRequest(BuildContext context, String userId) async {
  try {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception("User not authenticated");
    }

    // Create collaboration request data
    final requestData = {
      'requesterId': currentUserId,
      'receiverId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    };

    // Add collaboration request to Firestore
    await FirebaseFirestore.instance.collection('collaboration_requests').add(requestData);

    // Fetch receiver's username
    final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final receiverUsername = receiverDoc.data()?['username'] ?? 'User';

    // Notify both users about the collaboration request
    await FirebaseFirestore.instance.collection('notifications').add({
      'message': 'You have sent a collaboration request to $receiverUsername.',
      'userId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Optionally notify the receiver
    await FirebaseFirestore.instance.collection('notifications').add({
      'message': '$receiverUsername has sent you a collaboration request.',
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Collaboration request sent!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to send collaboration request')),
    );
  }
}
}

// Example of how to open the dialog:
void showUserProfileDialog(BuildContext context, UserModel user) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return UserProfileScreen(user: user);
    },
  );
}
