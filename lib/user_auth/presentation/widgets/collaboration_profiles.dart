import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollaborationProfilePictures extends StatelessWidget {
  final String collaborationId;

  const CollaborationProfilePictures({
    Key? key,
    required this.collaborationId,
  }) : super(key: key);

  Future<List<String>> _getUserIds(String collaborationId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('collaborations')
          .doc(collaborationId)
          .get();

      if (snapshot.exists) {
        List<String> userIds = List<String>.from(snapshot.get('users'));
        return userIds;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching user IDs: $e');
      return [];
    }
  }

  Future<String?> _getUserProfilePictureUrl(String userId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        return snapshot.get('profilePictureUrl');
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching profile picture URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _getUserIds(collaborationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const CircleAvatar(
            radius: 12,
            backgroundColor: Colors.red,
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: snapshot.data!.map((userId) {
              return FutureBuilder<String?>(
                future: _getUserProfilePictureUrl(userId),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState == ConnectionState.waiting) {
                    return const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey,
                    );
                  } else if (profileSnapshot.hasError) {
                    return const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                    );
                  } else if (profileSnapshot.hasData && profileSnapshot.data != null) {
                    return CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(profileSnapshot.data!),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              );
            }).toList(),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
