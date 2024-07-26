// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, unused_field, unused_import

import 'dart:async';

import 'package:checkit_off/main.dart';
import 'package:checkit_off/user_auth/presentation/widgets/completed_tasks_confirmation.dart';
import 'package:checkit_off/user_auth/presentation/widgets/completed_tasks_counter.dart';
import 'package:checkit_off/user_auth/presentation/widgets/tasks_removed_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:checkit_off/global/models/task.dart';
import 'package:checkit_off/user_auth/presentation/screens/login.dart';
import 'package:checkit_off/user_auth/presentation/widgets/custom_drawer.dart';
import 'package:checkit_off/user_auth/presentation/widgets/menu_icon.dart';
import 'package:checkit_off/user_auth/presentation/widgets/delete_task_confirmation.dart';
import 'package:checkit_off/user_auth/presentation/screens/add_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Initialize the FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (notificationResponse) async {
        // Handle the notification tap here
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          // Navigate or perform an action based on the payload
          print('Notification tapped with payload: $payload');
        }
      },
    );
}

  Timer? _notificationTimer;

  

  @override
  void initState() {
    super.initState();
    _startNotificationTimer();
    _initializeNotifications(); 
    _deleteExpiredTasks();
  }

  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(const Duration(hours:2 ), (timer) async {
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
        .collection('users')
        .doc(_user.uid)
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
          .collection('users')
          .doc(_user!.uid)
          .collection('tasks')
          .where('deadline', isLessThan: now)
          .where('isCompleted', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        final taskName = doc['name'];
        final deadline = (doc['deadline'] as Timestamp).toDate();

        await doc.reference.delete();

        // Show the TaskRemovedDialog instead of AlertDialog
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
      print('Error deleting expired tasks: $e');
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (Route<dynamic> route) => false,
    );
  }

  void _confirmDeleteTask(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteTaskConfirmationDialog(
          onConfirm: () async {
            Navigator.of(context).pop();
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user!.uid)
                  .collection('tasks')
                  .doc(taskId)
                  .delete();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted successfully')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error deleting task')),
              );
            }
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
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

  void _showPopupMenu(
      BuildContext context, Offset offset, Task task, String taskId) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        offset & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'Edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem<String>(
          value: 'Delete',
          child: Text('Delete'),
        ),
      ],
    ).then((String? result) {
      if (result == 'Edit') {
        _editTask(task, taskId);
      } else if (result == 'Delete') {
        _confirmDeleteTask(context, taskId);
      }
    });
  }

  void _markTaskAsCompleted(String taskId) async {
    try {
      final taskDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('tasks')
          .doc(taskId);
      final taskDoc = await taskDocRef.get();

      if (!taskDoc.exists) {
        throw Exception('Task document does not exist');
      }

      final taskData = taskDoc.data() as Map<String, dynamic>;

      // Convert the deadline to DateTime if it's a Timestamp
      DateTime deadline = taskData['deadline'] is Timestamp
          ? (taskData['deadline'] as Timestamp).toDate()
          : taskData['deadline'];

      final completedTaskData = {
        ...taskData,
        'isCompleted': true,
        'completionTimestamp': DateTime.now().millisecondsSinceEpoch,
        'completedAt': FieldValue.serverTimestamp(),
        'deadline': Timestamp.fromDate(deadline),
      };

      await taskDocRef.delete();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('completed_tasks')
          .add(completedTaskData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task marked as completed')),
      );
    } catch (e) {
      print('Error marking task as completed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error marking task as completed')),
      );
    }
  }

  void _confirmCompleteTask(String taskId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CompleteTaskConfirmationDialog(
          onConfirm: () {
            Navigator.of(context).pop();
            _markTaskAsCompleted(taskId);
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 2,
        leading: MenuIcon(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: const Color.fromARGB(255, 24, 24, 24),
        title: const Text(
          'Track your tasks ...',
          style: TextStyle(color: Color.fromARGB(255, 250, 171, 0)),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CompletedTasksCounter(),
          ),
        ],
      ),
      drawer: CustomDrawer(signOut: _signOut),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Image.asset(
                    'assets/images/app-logo2.png',
                    height: 100,
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user!.uid)
                        .collection('tasks')
                        .where('isCompleted', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                       return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/no_tasks.png',
                          height: 100,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No tasks available',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                      }

                      List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                      docs.sort((a, b) {
                        Timestamp aDeadline = a['deadline'];
                        Timestamp bDeadline = b['deadline'];
                        return aDeadline.compareTo(bDeadline);
                      });

                      List<QueryDocumentSnapshot> approachingDeadlineDocs =
                          docs.where((doc) {
                        Timestamp deadline = doc['deadline'];
                        return deadline.toDate().isBefore(
                            DateTime.now().add(const Duration(days: 3)));
                      }).toList();

                      List<QueryDocumentSnapshot> otherDocs = docs.where((doc) {
                        return !approachingDeadlineDocs.contains(doc);
                      }).toList();

                      return ListView(
                        children: [
                          if (approachingDeadlineDocs.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Approaching Deadlines',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...approachingDeadlineDocs.map((doc) {
                              Task task = Task.fromMap(
                                doc.data() as Map<String, dynamic>,
                              );
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
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                task.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                task.description,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                onLongPressStart:
                                    (LongPressStartDetails details) {
                                  _showPopupMenu(
                                    context,
                                    details.globalPosition,
                                    task,
                                    doc.id,
                                  );
                                },
                                child: Card(
                                  color: const Color.fromARGB(255, 55, 55, 55),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ExpansionTile(
                                    title: Row(
                                      children: [
                                        _buildPriorityIcon(task.priority),
                                        const SizedBox(width: 8),
                                        Text(
                                          task.name,
                                          style: const TextStyle(
                                            color: Colors.yellow,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      'Due: ${task.deadline.toLocal().toString().split(' ')[0]}',
                                      style: const TextStyle(
                                        color:
                                            Color.fromARGB(255, 163, 163, 163),
                                      ),
                                    ),
                                    childrenPadding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    trailing: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: task.isCompleted,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                _confirmCompleteTask(doc.id);
                                              } else {
                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(_user.uid)
                                                    .collection('tasks')
                                                    .doc(doc.id)
                                                    .update(
                                                        {'isCompleted': value});
                                              }
                                            });
                                          },
                                          activeColor: Colors.yellow,
                                          checkColor: Colors.black,
                                        ),
                                      ],
                                    ),
                                    children: [
                                      Text(
                                        task.description,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Pending Tasks',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...otherDocs.map((doc) {
                            Task task = Task.fromMap(
                              doc.data() as Map<String, dynamic>,
                            );
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
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              task.description,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              onLongPressStart:
                                  (LongPressStartDetails details) {
                                _showPopupMenu(
                                  context,
                                  details.globalPosition,
                                  task,
                                  doc.id,
                                );
                              },
                              child: Card(
                                color: const Color.fromARGB(255, 55, 55, 55),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: ExpansionTile(
                                  title: Row(
                                    children: [
                                      _buildPriorityIcon(task.priority),
                                      const SizedBox(width: 8),
                                      Text(
                                        task.name,
                                        style: const TextStyle(
                                          color: Colors.yellow,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'Due: ${task.deadline.toLocal().toString().split(' ')[0]}',
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 163, 163, 163),
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  trailing: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: task.isCompleted,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _confirmCompleteTask(doc.id);
                                            } else {
                                              FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(_user.uid)
                                                  .collection('tasks')
                                                  .doc(doc.id)
                                                  .update(
                                                      {'isCompleted': value});
                                            }
                                          });
                                        },
                                        activeColor: Colors.yellow,
                                        checkColor: Colors.black,
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Text(
                                      task.description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellow,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return const FractionallySizedBox(
                heightFactor: 0.5,
                child: AddTask(),
              );
            },
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
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
}
