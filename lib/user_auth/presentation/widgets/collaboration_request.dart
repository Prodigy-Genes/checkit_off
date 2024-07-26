// ignore_for_file: use_build_context_synchronously

import 'package:checkit_off/main.dart';
import 'package:checkit_off/user_auth/presentation/screens/accepted_collaboration.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

// ignore: must_be_immutable
class CollaborationRequestsScreen extends StatelessWidget {
  CollaborationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final Logger logger = Logger();

    return Column(
      children: [
        Expanded(child: _buildCollaborationRequests(context, currentUserId, logger)),
        Expanded(child: _buildTaskCompletionRequests(context, currentUserId, logger)),
        Expanded(child: _buildTaskDeletionRequests(context, currentUserId, logger)),
      ],
    );
  }

  Widget _buildCollaborationRequests(BuildContext context, String? currentUserId, Logger logger) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('collaboration_requests')
          .where('receiverId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          logger.e("Error fetching collaboration requests: ${snapshot.error}");
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return const Center(child: Text('No collaboration requests.', style: TextStyle(color: Colors.orange)));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final requesterId = request['requesterId'];
            final status = request['status'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(requesterId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text('Loading...'));
                }

                final requesterUsername = userSnapshot.data?.get('username') ?? 'Unknown User';

                return ListTile(
                  title: Text('Request from: $requesterUsername', style: const TextStyle(color: Colors.orangeAccent)),
                  subtitle: Text('Status: $status', style: const TextStyle(color: Colors.lightGreen)),
                  trailing: status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _acceptRequest(request.id, requesterId, context, logger),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectRequest(request.id, requesterId, logger),
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRequest(context, request.id, logger),
                        ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTaskCompletionRequests(BuildContext context, String? currentUserId, Logger logger) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('task_completion_requests')
          .where('collaboratorId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          logger.e("Error fetching task completion requests: ${snapshot.error}");
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return const Center(child: Text('No task completion requests.'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final requesterId = request['requesterId'];
            final status = request['status'];
            final taskId = request['taskId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(requesterId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text('Loading...'));
                }

                final requesterUsername = userSnapshot.data?.get('username') ?? 'Unknown User';

                return ListTile(
                  title: Text('Completion request from: $requesterUsername'),
                  subtitle: Text('Status: $status'),
                  trailing: status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _acceptCompletionRequest(request.id, requesterId, taskId, context, logger),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectCompletionRequest(request.id, requesterId, logger),
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRequest(context, request.id, logger),
                        ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTaskDeletionRequests(BuildContext context, String? currentUserId, Logger logger) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('task_deletion_requests')
          .where('collaboratorId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          logger.e("Error fetching task deletion requests: ${snapshot.error}");
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return const Center(child: Text('No task deletion requests.'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final requesterId = request['requesterId'];
            final status = request['status'];
            final taskId = request['taskId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(requesterId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text('Loading...'));
                }

                final requesterUsername = userSnapshot.data?.get('username') ?? 'Unknown User';

                return ListTile(
                  title: Text('Deletion request from: $requesterUsername'),
                  subtitle: Text('Status: $status'),
                  trailing: status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _acceptDeletionRequest(request.id, requesterId, taskId, context, logger),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectDeletionRequest(request.id, requesterId, logger),
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRequest(context, request.id, logger),
                        ),
                );
              },
            );
          },
        );
      },
    );
  }

  // A list to store collaboration IDs for the current user
List<String> collaborationIds = [];

Future<void> _acceptRequest(String requestId, String requesterId, BuildContext context, Logger logger) async {
  try {
    logger.i("Accepting collaboration request: $requestId");

    // Update the status of the collaboration request
    await FirebaseFirestore.instance
        .collection('collaboration_requests')
        .doc(requestId)
        .update({'status': 'accepted'});

    logger.i("Collaboration request $requestId accepted.");

    // Create the collaboration ID for both users
    String collaborationId = await _getOrCreateCollaborationId(requesterId);
    collaborationIds.add(collaborationId); // Store the collaboration ID
    logger.i("Collaboration ID created: $collaborationId");

    // Notify both users
    await _sendNotification(requesterId, 'Your collaboration request has been accepted.');
    logger.i("Notification sent to requester: $requesterId");

    await _sendNotification(FirebaseAuth.instance.currentUser!.uid, 'You have accepted a collaboration request.');
    logger.i("Notification sent to current user: ${FirebaseAuth.instance.currentUser!.uid}");

    // Navigate to the collaboration screen to add tasks
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Collaboration(collaborationId: collaborationId),
      ),
    );

    logger.i("Navigating to collaboration screen with ID: $collaborationId");
  } catch (e) {
    logger.e("Error accepting collaboration request: $e");
    
    if (e is FirebaseException && e.code == 'permission-denied') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to accept this request.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept request.')),
      );
    }
  }
}


Future<String> _getOrCreateCollaborationId(String requesterId) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    try {
      // Fetch requester's profile picture URL
      DocumentSnapshot requesterSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(requesterId)
          .get();
      String requesterProfilePictureUrl = requesterSnapshot.get('profilePictureUrl');
      
      // Fetch current user's profile picture URL
      DocumentSnapshot currentUserSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      String currentUserProfilePictureUrl = currentUserSnapshot.get('profilePictureUrl');

      logger.i("Profile picture URLs fetched - Requester: $requesterProfilePictureUrl, Current User: $currentUserProfilePictureUrl");

      // Create collaboration for both users
      DocumentReference docRef = await FirebaseFirestore.instance.collection('collaborations').add({
        'users': [currentUser.uid, requesterId],  // Include both users
        'created_at': FieldValue.serverTimestamp(),
      });
      String collaborationId = docRef.id; // Get the created collaboration ID
      logger.i("Collaboration ID $collaborationId created for users: ${currentUser.uid} and $requesterId");
      
      return collaborationId; // Return the created collaboration ID
    } catch (e) {
      logger.e("Error creating collaboration: $e");
      rethrow; // Rethrow the error for handling in the caller method
    }
  } else {
    throw Exception("User not authenticated");
  }
}


// Method to retrieve collaboration IDs for the current user
List<String> getCollaborationIds() {
  return collaborationIds;
}



Future<void> _sendNotification(String userId, String message) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'message': message,
    'userId': userId,
    'timestamp': FieldValue.serverTimestamp(),
  });
}





  Future<void> _rejectRequest(String requestId, String requesterId, Logger logger) async {
    try {
      logger.i("Rejecting collaboration request: $requestId");
      await FirebaseFirestore.instance
          .collection('collaboration_requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      logger.i("Request rejected, notifying requester: $requesterId");
      await FirebaseFirestore.instance.collection('notifications').add({
        'message': 'Your collaboration request has been rejected.',
        'userId': requesterId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e("Error rejecting collaboration request: $e");
    }
  }

  Future<void> _deleteRequest(BuildContext context, String requestId, Logger logger) async {
    try {
      logger.i("Deleting collaboration request: $requestId");
      await FirebaseFirestore.instance.collection('collaboration_requests').doc(requestId).delete();
      logger.i("Request deleted successfully.");
    } catch (e) {
      logger.e("Error deleting collaboration request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete request.')),
      );
    }
  }

  Future<void> _acceptCompletionRequest(String requestId, String requesterId, String taskId, BuildContext context, Logger logger) async {
    try {
      logger.i("Accepting task completion request: $requestId");
      await FirebaseFirestore.instance
          .collection('task_completion_requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      logger.i("Request accepted for task: $taskId");
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'completed': true});

      logger.i("Task marked as completed: $taskId");
    } catch (e) {
      logger.e("Error accepting task completion request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept completion request.')),
      );
    }
  }

  Future<void> _rejectCompletionRequest(String requestId, String requesterId, Logger logger) async {
    try {
      logger.i("Rejecting task completion request: $requestId");
      await FirebaseFirestore.instance
          .collection('task_completion_requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      logger.i("Request rejected: $requestId");
      await FirebaseFirestore.instance.collection('notifications').add({
        'message': 'Your task completion request has been rejected.',
        'userId': requesterId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e("Error rejecting task completion request: $e");
    }
  }

  Future<void> _acceptDeletionRequest(String requestId, String requesterId, String taskId, BuildContext context, Logger logger) async {
    try {
      logger.i("Accepting task deletion request: $requestId");
      await FirebaseFirestore.instance
          .collection('task_deletion_requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      logger.i("Request accepted for task: $taskId");
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();

      logger.i("Task deleted: $taskId");
    } catch (e) {
      logger.e("Error accepting task deletion request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept deletion request.')),
      );
    }
  }

  Future<void> _rejectDeletionRequest(String requestId, String requesterId, Logger logger) async {
    try {
      logger.i("Rejecting task deletion request: $requestId");
      await FirebaseFirestore.instance
          .collection('task_deletion_requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      logger.i("Request rejected: $requestId");
      await FirebaseFirestore.instance.collection('notifications').add({
        'message': 'Your task deletion request has been rejected.',
        'userId': requesterId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e("Error rejecting task deletion request: $e");
    }
  }
}
