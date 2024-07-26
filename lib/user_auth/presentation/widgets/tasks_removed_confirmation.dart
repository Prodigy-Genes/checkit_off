import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskRemovedDialog extends StatelessWidget {
  final String taskName;
  final DateTime deadline;

  const TaskRemovedDialog({
    required this.taskName,
    required this.deadline,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Image.asset(
            'assets/images/removed.png', 
            height: 30,
            width: 30,
          ),
          const SizedBox(width: 10),
          const Text(
            'Task Removed',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18, // Increase font size for emphasis
            ),
          ),
        ],
      ),
      content: Text(
        'Unfortunately, the task "$taskName" with a deadline of ${DateFormat('yyyy-MM-dd').format(deadline)} has been removed.', // Adjusted text to convey disappointment
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16, // Adjust font size for clarity
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'OK',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16, // Adjust font size for button text
            ),
          ),
        ),
      ],
    );
  }
}
