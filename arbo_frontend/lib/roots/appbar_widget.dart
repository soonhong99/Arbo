import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/widgets/search_widgets/search_design_widget.dart';
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
    final double screenWidth = MediaQuery.of(context).size.width;

    return SliverAppBar(
      floating: true,
      snap: true,
      foregroundColor: Colors.green,
      title: Row(
        children: [
          TextButton(
            onPressed: () {
              selectedIndex = -1;
              Navigator.pushNamed(
                context,
                '/',
              );
            },
            child: const Text('SelfmadeDeco'),
          ),
          // const Text('자보'),
          const SizedBox(
            width: 60,
          ),
          SearchDesignBar(
            screenWidth: screenWidth / 2,
          ),
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
            child: Row(
              children: [
                Icon(user == null ? Icons.login : Icons.person),
                Text(user == null ? '로그인' : '마이페이지'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
