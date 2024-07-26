import 'package:checkit_off/user_auth/presentation/widgets/collaboration_request.dart';
import 'package:checkit_off/user_auth/presentation/widgets/user_notifications.dart';
import 'package:flutter/material.dart';

class CollaborationNotificationScreen extends StatelessWidget {
  const CollaborationNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Collaboration Notifications',
          style: TextStyle(color: Color.fromARGB(255, 255, 123, 0), fontSize: 18), // White text color for the title
        ),
        backgroundColor: Colors.black, // Black background for the app bar
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Colors.yellow, // Yellow color for the icon
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserNotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 40, 39, 39), 
        child: CollaborationRequestsScreen(), 
      ),
    );
  }
}
