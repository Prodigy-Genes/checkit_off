import 'package:flutter/material.dart';

class DeleteTaskConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DeleteTaskConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
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
            'assets/images/delete.png', 
            height: 30,
            width: 30,
          ),
          const SizedBox(width: 10),
          const Text(
            'Delete Task',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to delete this task? This action cannot be undone.',
        style: TextStyle(color: Colors.black),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
          onPressed: onCancel,
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: onConfirm,
          child: const Text(
            'Yes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
