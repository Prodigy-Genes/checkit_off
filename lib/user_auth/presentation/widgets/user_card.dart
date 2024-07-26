import 'package:checkit_off/global/models/user.dart';
import 'package:checkit_off/user_auth/presentation/widgets/user__profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final String userId;

  const UserCard({Key? key, required this.userId}) : super(key: key);

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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('User not found'));
        }

        UserModel user = UserModel.fromDocument(snapshot.data!);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(user: user),
              ),
            );
          },
          child: SizedBox(
            width: 300,
            height: MediaQuery.of(context).size.height * 0.2,
            child: Card(
              color: const Color.fromARGB(255, 62, 59, 59),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue,
                      backgroundImage: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                          ? NetworkImage(user.profilePictureUrl!)
                          : null,
                      child: (user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 30, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 4),
                              FutureBuilder<int>(
                                future: getCompletedTasksCount(userId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Text(
                                      'Loading...',
                                      style: TextStyle(color: Colors.yellow),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return const Text(
                                      'Error',
                                      style: TextStyle(color: Colors.red),
                                    );
                                  }
                                  return Text(
                                    'Completed Tasks: ${snapshot.data ?? 0}', // Handle null case
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.yellow,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
