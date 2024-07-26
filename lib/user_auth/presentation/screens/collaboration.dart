// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, unused_element

import 'package:checkit_off/global/common/toast.dart';
import 'package:checkit_off/user_auth/presentation/screens/accepted_collaboration.dart';
import 'package:checkit_off/user_auth/presentation/widgets/user_card.dart';
import 'package:checkit_off/user_auth/presentation/widgets/user_leaderboard.dart';
import 'package:checkit_off/user_auth/presentation/widgets/user_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  _CollaborationScreenState createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  List<String> userIds = [];
  String? collaborationId;
  String? selectedReceiverId; // Variable to hold the selected receiver ID
  final Logger logger = Logger();
  List<String> collaborationIds = []; // List to store collaboration IDs

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _loadCollaborationIds(); // Load collaboration IDs when the state initializes

  }

   // Method to load collaboration IDs from Firestore or other storage
  Future<void> _loadCollaborationIds() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Fetch collaboration IDs from Firestore
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('collaborations')
            .where('users', arrayContains: currentUser.uid)
            .get();

        // Populate the collaborationIds list with the document IDs
        collaborationIds = snapshot.docs.map((doc) => doc.id).toList();
        logger.i("Collaboration IDs loaded: $collaborationIds");
      } else {
        logger.e("No current user logged in.");
      }
    } catch (e) {
      logger.e("Error loading collaboration IDs: $e");
    }
  }

   // Method to return collaboration IDs
  List<String> getCollaborationIds() {
    return collaborationIds;
  }

  Future<void> _fetchUsers() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        logger.i("Fetching users for ${currentUser.uid}");
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance.collection('users').get();
        setState(() {
          userIds = snapshot.docs.map((doc) => doc.id).toList();
        });
        logger.i("Fetched ${userIds.length} users.");
      } else {
        _handleUnauthenticatedUser();
      }
    } catch (e) {
      _handleFetchUsersError(e);
    }
  }

  void _handleUnauthenticatedUser() {
    showToast(context, "User not authenticated");
    logger.e("User not authenticated.");
  }

  void _handleFetchUsersError(dynamic error) {
    showToast(context, "Failed to fetch users: $error");
    logger.e("Error fetching users: $error");
  }

  Future<String> _getOrCreateCollaborationId(
      String requestId, String requesterId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        logger.i(
            "Creating collaboration for ${currentUser.uid} and $requesterId");

        // Create collaboration with both users
        DocumentReference docRef =
            await FirebaseFirestore.instance.collection('collaborations').add({
          'users': [currentUser.uid, requesterId], // Include both users
          'created_at': FieldValue.serverTimestamp(),
        });

        logger.i("Collaboration created with ID: ${docRef.id}");
        return docRef.id; // Return the collaboration ID
      } else {
        throw Exception("User not authenticated");
      }
    } catch (e) {
      logger.e("Error creating collaboration: $e");
      rethrow; // Rethrow the exception to handle it in the calling method
    }
  }

  void _handleCollaborationError(dynamic error) {
    showToast(context, "Failed to create or fetch collaboration: $error");
    logger.e("Error creating or fetching collaboration: $error");
  }

  void _selectReceiver(String receiverId) {
    setState(() {
      selectedReceiverId = receiverId; // Update the selected receiver ID
    });
    logger.i("Selected receiver: $receiverId");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Collaborate with friends',
                  style: TextStyle(
                      color: Color.fromARGB(255, 255, 174, 0), fontSize: 16),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.group,
                    color: Color.fromARGB(255, 5, 202, 58),
                  ),
                  onPressed: () {
                    // Check if there are stored collaboration IDs
                    List<String> collaborationIds = getCollaborationIds();
                    if (collaborationIds.isNotEmpty) {
                      // Navigate to the first collaboration ID or handle the selection
                      String collaborationId =
                          collaborationIds.first; // Modify this logic if needed
                      logger.i(
                          "Navigating to collaboration with ID: $collaborationId");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Collaboration(collaborationId: collaborationId),
                        ),
                      );
                    } else {
                      // Show a SnackBar if no collaboration IDs are stored
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "You do not have a collaboration ID. Please create or join a collaboration."),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      logger.e("No collaboration ID assigned.");
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: Color.fromARGB(255, 255, 0, 0),
                  ),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: UserSearchDelegate(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        color: const Color.fromARGB(255, 40, 39, 39),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserCards(),
            const SizedBox(height: 16),
            const Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Color.fromARGB(255, 255, 111, 0),
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: LeaderboardWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: userIds.map((userId) {
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _selectReceiver(userId), // Set receiver when tapped
              child: UserCard(userId: userId),
            ),
          );
        }).toList(),
      ),
    );
  }
}
