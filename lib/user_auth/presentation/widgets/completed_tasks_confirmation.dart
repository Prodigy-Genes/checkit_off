import 'package:flutter/material.dart';

class CompleteTaskConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CompleteTaskConfirmationDialog({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Image.asset(
            'assets/images/complete.png', 
            height: 30,
            width: 30,
          ),
          const SizedBox(width: 10),
          const Text(
            'Complete Task',
            style: TextStyle(
              color: Color(0xFFF0AB00), // Custom orange color
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to mark this task as completed?',
        style: TextStyle(color: Colors.black),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.green, 
          ),
          child: const Text(
            'Yes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
        ),
      ],
    );
  }
}
