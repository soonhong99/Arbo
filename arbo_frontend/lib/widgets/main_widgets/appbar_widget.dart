import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomSliverAppBar extends StatelessWidget {
  final User? user;
  final String? nickname;
  final VoidCallback? onLogout;
  final VoidCallback? onLogin;
  final VoidCallback? onUserInfo;

  const CustomSliverAppBar({
    super.key,
    this.user,
    this.nickname,
    this.onLogout,
    this.onLogin,
    this.onUserInfo,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      foregroundColor: Colors.green,
      title: Row(
        children: [
          const Text('자보'),
          const Spacer(),
          if (user != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                '$nickname',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: onLogout,
            ),
          ],
          TextButton(
            onPressed: () {
              user == null ? onLogin?.call() : onUserInfo?.call();
            },
            child: const Row(
              children: [
                Icon(Icons.person),
                Text('마이페이지'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
