import 'package:checkit_off/global/models/user.dart';
import 'package:checkit_off/user_auth/presentation/widgets/user__profile.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSearchDelegate extends SearchDelegate {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        color: Color.fromARGB(255, 0, 0, 0),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.white,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Color.fromARGB(255, 255, 157, 0)),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 255, 132, 0)),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _fetchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found', style: TextStyle(color: Colors.white)));
        }

        final results = snapshot.data!;

        return Container(
          color: Colors.black,
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  results[index].username,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(user: results[index]),
                    ),
                  );
                },
                tileColor: const Color.fromARGB(255, 185, 185, 185),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _fetchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No suggestions found', style: TextStyle(color: Colors.white)));
        }

        final suggestions = snapshot.data!;

        return Container(
          color: Colors.black,
          child: ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  suggestions[index].username,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  query = suggestions[index].username;
                  showResults(context);
                },
                tileColor: Colors.grey[850],
              );
            },
          ),
        );
      },
    );
  }

  Future<List<UserModel>> _fetchUsers(String query) async {
    final List<UserModel> users = [];

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var doc in snapshot.docs) {
      UserModel user = UserModel.fromDocument(doc);
      if (user.username.toLowerCase().contains(query.toLowerCase())) {
        users.add(user);
      }
    }

    return users;
  }
}
