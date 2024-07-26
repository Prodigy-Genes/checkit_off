// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:async';
import 'package:checkit_off/global/models/task.dart';
import 'package:checkit_off/user_auth/presentation/screens/addtask_collaboration.dart';
import 'package:checkit_off/user_auth/presentation/widgets/collaboration_profiles.dart';
import 'package:checkit_off/user_auth/presentation/widgets/completed_tasks_confirmation.dart';
import 'package:checkit_off/user_auth/presentation/widgets/tasks_removed_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:checkit_off/user_auth/presentation/widgets/delete_task_confirmation.dart';
import 'package:checkit_off/user_auth/presentation/screens/add_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class Collaboration extends StatefulWidget {
  final String collaborationId;

  const Collaboration({Key? key, required this.collaborationId})
      : super(key: key);

  @override
  _CollaborationState createState() => _CollaborationState();
}

class _CollaborationState extends State<Collaboration> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Logger logger = Logger();


  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _startNotificationTimer();
    _deleteExpiredTasks();

  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) async {
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          logger.i('Notification tapped with payload: $payload');
        }
      },
    );
  }

  void _startNotificationTimer() {
    _notificationTimer =
        Timer.periodic(const Duration(hours: 2), (timer) async {
      await _checkUpcomingDeadlines();
    });
  }

  Future<void> _checkUpcomingDeadlines() async {
    logger.i('Checking for upcoming deadlines...');
    if (_user == null) {
      logger.e('User is not logged in.');
      return;
    }

    try {
      final now = DateTime.now();
      final upcomingDeadline = now.add(const Duration(days: 3));
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('collaborations')
          .doc(widget.collaborationId)
          .collection('tasks')
          .where('deadline', isLessThanOrEqualTo: upcomingDeadline)
          .where('isCompleted', isEqualTo: false)
          .get();

      logger.i('Found ${tasksSnapshot.docs.length} upcoming tasks.');

      for (var taskDoc in tasksSnapshot.docs) {
        final taskName = taskDoc['name'];
        await FirebaseFirestore.instance.collection('notifications').add({
          'message': 'Reminder: Your task "$taskName" is due soon!',
          'userId': _user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        logger.i('Notification sent for task: $taskName');

        await taskDoc.reference.update({'reminderSent': true});
      }
    } catch (e) {
      logger.e('Error checking deadlines: $e');
    }
  }

  Future<void> _deleteExpiredTasks() async {
    try {
      final now = DateTime.now();
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('collaborations')
          .doc(widget.collaborationId)
          .collection('tasks')
          .where('deadline', isLessThan: now)
          .where('isCompleted', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        final taskName = doc['name'];
        final deadline = (doc['deadline'] as Timestamp).toDate();

        await doc.reference.delete();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return TaskRemovedDialog(
              taskName: taskName,
              deadline: deadline,
            );
          },
        );
      }
    } catch (e) {
      logger.e('Error deleting expired tasks: $e');
    }
  }

  Future<void> _notifyCollaborationUsers(String message) async {
    try {
      final collaborationDoc = await FirebaseFirestore.instance
          .collection('collaborations')
          .doc(widget.collaborationId)
          .get();

      final collaborationData = collaborationDoc.data() as Map<String, dynamic>;
      final users = collaborationData['users'] as List<dynamic>;

      for (var userId in users) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'message': message,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      logger.e('Error notifying collaboration users: $e');
    }
  }

  void _confirmDeleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteTaskConfirmationDialog(
          onConfirm: () async {
            await _requestTaskDeletionConfirmation(task);
            await _notifyCollaborationUsers(
                'Task "${task.name}" has been deleted.');
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _requestTaskDeletionConfirmation(Task task) async {
    try {
      await FirebaseFirestore.instance
          .collection('collaborations')
          .doc(widget.collaborationId)
          .collection('tasks')
          .doc(task.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully')),
      );
    } catch (e) {
      logger.e('Error deleting task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting task')),
      );
    }
  }

  void _editTask(Task task, String taskId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: AddTask(
            task: task,
            taskId: taskId,
          ),
        );
      },
    );
  }

  void _confirmCompleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CompleteTaskConfirmationDialog(
          onConfirm: () {
            Navigator.of(context).pop();
            _requestTaskCompletionConfirmation(task);
            _notifyCollaborationUsers(
                'Task "${task.name}" has been completed.');
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _requestTaskCompletionConfirmation(Task task) async {
    try {
      final taskDocRef = FirebaseFirestore.instance
          .collection('collaborations')
          .doc(widget.collaborationId)
          .collection('tasks')
          .doc(task.id);

      final completedTaskData = {
        ...task.toJson(),
        'isCompleted': true,
        'completedByBoth': false,
      };

      await taskDocRef.update(completedTaskData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task marked as completed')),
      );
    } catch (e) {
      logger.e('Error marking task as completed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error marking task as completed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color.fromARGB(255, 24, 24, 24),
        title: const Text(
          'Collaboration tasks ...',
          style:
              TextStyle(color: Color.fromARGB(255, 250, 171, 0), fontSize: 20),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 249, 137, 0),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return FractionallySizedBox(
                heightFactor: 0.5,
                child: AddCollaborationTask(
                  collaborationId: widget.collaborationId,
                ),
              );
            },
          );
        },
        child: const Icon(
          Icons.add,
          color: Color.fromARGB(255, 250, 212, 0),
          size: 24,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('collaborations')
              .doc(widget.collaborationId)
              .collection('tasks')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error loading tasks'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No tasks found',
                      style: TextStyle(color: Colors.white)));
            }
            

            final taskDocs = snapshot.data!.docs;
            final tasks =
                taskDocs.map((doc) => Task.fromFirestore(doc)).toList();

            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  color: const Color.fromARGB(255, 50, 50, 50),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        _buildPriorityIcon(task.priority),
                        const SizedBox(width: 8),
                        Text(
                          task.name,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 250, 250, 250),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                        'Deadline: ${DateFormat('MMM d, yyyy - hh:mm a').format(task.deadline)}',
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                    children: [
                      ListTile(
                        title: Text(
                          task.description,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: Colors.orangeAccent,
                              onPressed: () {
                                _editTask(task, task.id);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () {
                                _confirmDeleteTask(context, task);
                              },
                            ),
                            if (!task.isCompleted)
                              IconButton(
                                icon: const Icon(Icons.check_circle),
                                color: Colors.green,
                                onPressed: () {
                                  _confirmCompleteTask(context, task);
                                },
                              ),
                          ],
                        ),
                      ),
                      CollaborationProfilePictures(collaborationId: widget.collaborationId)
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPriorityIcon(String priority) {
    IconData iconData;
    Color iconColor;

    switch (priority) {
      case 'Low':
        iconData = Icons.punch_clock_outlined;
        iconColor = Colors.green;
        break;
      case 'Medium':
        iconData = Icons.punch_clock_outlined;
        iconColor = Colors.orange;
        break;
      case 'High':
        iconData = Icons.punch_clock;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.punch_clock_outlined;
        iconColor = const Color.fromARGB(255, 83, 83, 83);
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 14,
    );
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }
}