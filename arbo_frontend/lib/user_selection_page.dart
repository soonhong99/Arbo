import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserSelectionPage extends StatelessWidget {
  final UserCredential userCredential;

  const UserSelectionPage({super.key, required this.userCredential});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Selection Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Welcome, ${userCredential.user?.email}!')),
            );
          },
          child: const Text('Show Snackbar'),
        ),
      ),
    );
  }
}
