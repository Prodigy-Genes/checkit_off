import 'package:checkit_off/global/models/task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final int completedTasks;
  final String? profilePictureUrl;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.completedTasks,
    this.profilePictureUrl,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      completedTasks: data['completedTasks'] ?? 0,
      profilePictureUrl: data['profilePictureUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'completedTasks': completedTasks,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}

// Function to undo task completion
Future<void> undoTaskCompletion(Task task, User user) async {
  final tasksCollection = Task.getUserTasksCollection(user);
  final completedTasksCollection = Task.getUserCompletedTasksCollection(user);
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

  try {
    if (task.id.isEmpty) {
      throw Exception('Task ID is empty');
    }

    // Use the task ID to delete the task from the completed tasks collection
    await completedTasksCollection.doc(task.id).delete();

    // Add the task back to the tasks collection with 'isCompleted' set to false
    await tasksCollection.doc(task.id).set({
      ...task.toMap(),
      'isCompleted': false,
    });

    // Decrement the user's completed tasks count
    await userDoc.update({
      'completedTasks': FieldValue.increment(-1),
    });
  } catch (e, stackTrace) {
    print('Error undoing task completion: $e');
    print(stackTrace);
  }
}
