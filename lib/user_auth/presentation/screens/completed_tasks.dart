// ignore_for_file: library_private_types_in_public_api

import 'package:checkit_off/global/models/task.dart';
import 'package:checkit_off/user_auth/presentation/widgets/undo_completion_confirmation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({Key? key}) : super(key: key);

  @override
  _CompletedTasksScreenState createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  void _confirmUndoTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UndoTaskConfirmationDialog(
          onConfirm: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            Navigator.of(context).pop();
            try {
              User user = FirebaseAuth.instance.currentUser!;
              undoTaskCompletion(task, user);

              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Task undo successful!',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                );
              }
            } catch (e, stackTrace) {
              print('Error undoing task completion: $e');
              print(stackTrace);
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error undoing task completion: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
            }
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    User user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Completed Tasks',
          style: TextStyle(color: Colors.orange),
        ),
        backgroundColor: const Color.fromARGB(255, 59, 59, 59),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Image.asset(
                'assets/images/completed.png',
                height: 150,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: getUserCompletedTasks(user),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/sad.png',
                          height: 100,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No completed tasks available',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }
                return ListView(
                  children: snapshot.data!.map((task) {
                    String formattedDate =
                        DateFormat('yyyy-MM-dd – kk:mm').format(task.deadline);

                    // Ensure task.collaborators is checked for null and emptiness
                    String collaborators = (task.collaborators != null &&
                            task.collaborators!.isNotEmpty)
                        ? 'Collaborators: ${task.collaborators!.join(', ')}'
                        : 'No collaborators';

                    return GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return FractionallySizedBox(
                              heightFactor: 0.5,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20.0),
                                  ),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.yellow,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      task.description,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      collaborators,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Card(
                        color: const Color.fromARGB(255, 61, 61, 61),
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: ExpansionTile(
                          title: Text(
                            task.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.description,
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Completed at: $formattedDate',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          // No undo button for collaboration tasks
                          trailing: (task.isCollaborative ??
                                  false) 

                              ? null
                              : IconButton(
                                  icon: const Icon(
                                    Icons.undo,
                                    color: Colors.blueGrey,
                                  ),
                                  onPressed: () {
                                    _confirmUndoTask(context, task);
                                  },
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Function to get user's completed tasks stream
Stream<List<Task>> getUserCompletedTasks(User user) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('completed_tasks')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Task.fromMap(doc.data()).copyWith(id: doc.id))
          .toList());
}
