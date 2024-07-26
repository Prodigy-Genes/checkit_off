import 'package:checkit_off/user_auth/presentation/screens/collaboration.dart';
import 'package:checkit_off/user_auth/presentation/screens/notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:checkit_off/user_auth/presentation/screens/completed_tasks.dart';
import 'package:checkit_off/user_auth/presentation/widgets/signout_confirmation.dart';
import 'package:checkit_off/user_auth/presentation/widgets/profile_picture_update.dart';
import 'package:checkit_off/user_auth/presentation/widgets/username_update.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomDrawer extends StatefulWidget {
  final VoidCallback signOut;

  const CustomDrawer({Key? key, required this.signOut}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  User? user = FirebaseAuth.instance.currentUser;

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SignOutConfirmationDialog(
          onConfirm: () {
            Navigator.of(context).pop();
            widget.signOut();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _updateUserName(BuildContext context) async {
    String? newUsername = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return UsernameUpdateDialog(user: user);
      },
    );

    if (newUsername != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'username': newUsername});

      await user!.updateDisplayName(newUsername);

      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });
    }
  }

  Future<void> _updateProfilePicture(BuildContext context) async {
    String? newProfilePictureUrl = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return ProfilePictureUpdateDialog(user: user);
      },
    );

    if (newProfilePictureUrl != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'profilePictureUrl': newProfilePictureUrl});

      await user!.updatePhotoURL(newProfilePictureUrl);

      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey[900], // Dark background color
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[800], // Darker header background color
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              child: UserAccountsDrawerHeader(
                accountName: GestureDetector(
                  onTap: () => _updateUserName(context),
                  child: Text(
                    user?.displayName ?? 'Guest',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? 'No email',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                currentAccountPicture: GestureDetector(
                  onTap: () => _updateProfilePicture(context),
                  child: CircleAvatar(
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    backgroundColor: Colors.orange,
                    child: user?.photoURL == null && user?.displayName?.isNotEmpty == true
                        ? Text(
                            user?.displayName?[0] ?? 'G',
                            style: const TextStyle(fontSize: 40.0, color: Colors.blue),
                          )
                        : null,
                  ),
                ),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text('Completed Tasks', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CompletedTasksScreen()),
                );
              },
            ),
            
            Divider(color: Colors.white.withOpacity(0.5)), // Lighter divider
            ListTile(
              leading: const Icon(Icons.group_add, color: Color.fromRGBO(255, 152, 0, 1)),
              title: const Text('Collaborations', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CollaborationScreen()),
                );
              },
            ),

            Divider(color: Colors.white.withOpacity(0.5)),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: const Text('Notifications', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CollaborationNotificationScreen()),
                );
              },
            ),
            

            Divider(color: Colors.white.withOpacity(0.5)), // Lighter divider
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text('Sign Out', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                _confirmSignOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
