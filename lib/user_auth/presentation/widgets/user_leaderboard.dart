import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardWidget extends StatelessWidget {
  const LeaderboardWidget({super.key});

  // Function to get the count of completed tasks for a user
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('completedTasks', descending: true)
          .limit(10) // Limit to top 10 users
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userId = user.id; // Get the user ID
            final username = user['username'] ?? 'Unknown User';
            final profilePictureUrl = user['profilePictureUrl'];

            return FutureBuilder<int>(
              future: getCompletedTasksCount(userId),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: Text(
                      username,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const CircularProgressIndicator(),
                  );
                }
                if (taskSnapshot.hasError) {
                  return ListTile(
                    title: Text(
                      username,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Text(
                      'Error',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final completedTasks = taskSnapshot.data ?? 0; // Fallback to 0 if null

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (profilePictureUrl != null && profilePictureUrl.isNotEmpty)
                        ? NetworkImage(profilePictureUrl)
                        : null,
                    child: (profilePictureUrl == null || profilePictureUrl.isEmpty)
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  title: Text(
                    username,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    'Tasks: $completedTasks',
                    style: const TextStyle(color: Colors.yellow),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
