// ignore_for_file: library_private_types_in_public_api

import 'package:checkit_off/global/models/task.dart';
import 'package:checkit_off/user_auth/presentation/screens/completed_tasks.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompletedTasksCounter extends StatefulWidget {
  const CompletedTasksCounter({Key? key}) : super(key: key);

  @override
  _CompletedTasksCounterState createState() => _CompletedTasksCounterState();
}

class _CompletedTasksCounterState extends State<CompletedTasksCounter> {

  @override
  Widget build(BuildContext context) {
    User user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<List<Task>>(
      stream: getUserCompletedTasks(user),
      builder: (context, AsyncSnapshot<List<Task>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        int completedTasksCount = snapshot.data!.where((task) {
          return task.isCompleted && task.deadline.isAfter(DateTime.now());
        }).length;

        if (completedTasksCount == 0) {
          return const SizedBox();
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 55),
            const Icon(
              Icons.star,
              color: Colors.yellow,
            ),
            const SizedBox(width: 4),
            Text(
              '$completedTasksCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}

