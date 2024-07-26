// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:checkit_off/global/models/task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class AddCollaborationTask extends StatefulWidget {
  final String collaborationId;
  final Task? task;
  final String? taskId;

  const AddCollaborationTask({
    Key? key,
    required this.collaborationId,
    this.task,
    this.taskId,
  }) : super(key: key);

  @override
  State<AddCollaborationTask> createState() => _AddCollaborationTaskState();
}

class _AddCollaborationTaskState extends State<AddCollaborationTask> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _priority = 'Medium';
  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _nameController.text = widget.task!.name;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.deadline;
      _priority = widget.task!.priority;
    }
  }

  Future<void> _addOrUpdateTask() async {
  if (_formKey.currentState!.validate()) {
    String taskId = widget.taskId ?? FirebaseFirestore.instance.collection('collaborations').doc(widget.collaborationId).collection('tasks').doc().id;
    Task newTask = Task(
      id: taskId,
      name: _nameController.text,
      description: _descriptionController.text,
      deadline: _selectedDate,
      priority: _priority,
      isCompleted: widget.task?.isCompleted ?? false,
      isCollaborative: true,
      collaborators: [],
    );

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Check if the collaboration document exists
        DocumentSnapshot collaborationDoc = await FirebaseFirestore.instance
            .collection('collaborations')
            .doc(widget.collaborationId)
            .get();

        if (!collaborationDoc.exists) {
          _showSnackBar('Collaboration not found.');
          logger.w('Collaboration document ${widget.collaborationId} does not exist.');
          return;
        }

        // Check if the document data is null
        Map<String, dynamic>? collaborationData = collaborationDoc.data() as Map<String, dynamic>?;
        if (collaborationData == null) {
          _showSnackBar('Collaboration data is null.');
          logger.w('Collaboration document ${widget.collaborationId} has null data.');
          return;
        }

        // Check if the users field is null or not a list
        if (collaborationData['users'] == null || collaborationData['users'] is! List<dynamic>) {
          _showSnackBar('Users data is invalid.');
          logger.w('Users field in document ${widget.collaborationId} is null or not a list.');
          return;
        }

        // Check if the user is a collaborator
        List<dynamic> users = collaborationData['users'];
        if (!users.contains(user.uid)) {
          _showSnackBar('You must be a collaborator to add a task.');
          logger.w('User ${user.uid} tried to add a task but is not a collaborator.');
          return;
        }

        // Add or update the task in Firestore
        await FirebaseFirestore.instance
            .collection('collaborations')
            .doc(widget.collaborationId)
            .collection('tasks')
            .doc(taskId)
            .set(newTask.toMap());

        // Send a notification with deadline and priority
        await _sendNotification(user.uid, newTask.name, newTask.deadline, newTask.priority);
        logger.i('Task added successfully: $taskId');
        Navigator.pop(context);
      } catch (e) {
        logger.e('Error adding/updating task: $e');
        _showSnackBar('Failed to add task. Please try again.');
      }
    } else {
      _showSnackBar('User is not authenticated.');
    }
  }
}


  Future<void> _sendNotification(String userId, String taskName, DateTime deadline, String priority) async {
    final timeRemaining = deadline.difference(DateTime.now());
    String timeRemainingMessage;

    if (timeRemaining.isNegative) {
      timeRemainingMessage = 'This task is overdue.';
    } else {
      final days = timeRemaining.inDays;
      final hours = timeRemaining.inHours.remainder(24);
      timeRemainingMessage = 'You have $days days and $hours hours to complete this task.';
    }

    await FirebaseFirestore.instance.collection('notifications').add({
      'message': 'You have added a new task: $taskName. Priority: $priority. $timeRemainingMessage',
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 24, 24, 24),
      appBar: AppBar(
        title: const Text('Add Task'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 36, 36, 36),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Task Name',
                    labelStyle: const TextStyle(color: Colors.orange),
                    prefixIcon: const Icon(Icons.title, color: Colors.yellow),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 45, 45, 45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a task name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: Colors.orange),
                    prefixIcon: const Icon(Icons.description, color: Colors.yellow),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 45, 45, 45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Due Date', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${_selectedDate.toLocal()}'.split(' ')[0],
                    style: const TextStyle(color: Colors.yellow),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: Colors.yellow),
                  onTap: _selectDate,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    labelStyle: const TextStyle(color: Colors.orange),
                    prefixIcon: const Icon(Icons.priority_high, color: Colors.yellow),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 45, 45, 45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color.fromARGB(255, 36, 36, 36),
                  items: <String>['High', 'Medium', 'Low'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _priority = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.yellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _addOrUpdateTask,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(widget.task == null ? 'Add Task' : 'Update Task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.yellow,
              onPrimary: Colors.black,
              surface: Color.fromARGB(255, 36, 36, 36),
              onSurface: Colors.yellow,
            ),
            dialogBackgroundColor: const Color.fromARGB(255, 24, 24, 24),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
