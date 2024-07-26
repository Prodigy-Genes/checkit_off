// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserNotificationsScreen extends StatelessWidget {
  const UserNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    Future<void> _deleteNotification(String notificationId) async {
  try {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
  } catch (e) {
    // Handle error if needed
    print('Error deleting notification: $e');
  }
}


    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Notifications',
          style: TextStyle(color: Colors.orange),
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: const Color.fromARGB(255, 40, 39, 39),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: currentUserId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data!.docs;

            if (notifications.isEmpty) {
              return const Center(child: Text('No notifications.', style: TextStyle(color: Colors.orange)));
            }

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Card(
                  color: const Color.fromARGB(255, 60, 60, 60),
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(
                      notification['message'],
                      style: const TextStyle(color: Colors.yellow),
                    ),
                    subtitle: Text(
                      notification['timestamp']?.toDate().toString() ?? '',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteNotification(notification.id),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

