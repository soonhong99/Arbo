import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoWidget extends StatelessWidget {
  final User user;

  const UserInfoWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('마이페이지'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('이메일: ${user.email}'),
            Text('UID: ${user.uid}'),
            // Add more user information here
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('확인'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
