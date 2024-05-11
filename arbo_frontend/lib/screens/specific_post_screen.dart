import 'package:flutter/material.dart';

class SpecificPostScreen extends StatelessWidget {
  final String postTopic;
  final String nickname;
  final String title;
  final String content;
  final int likes;
  final int comments;
  final DateTime timestamp;
  final Widget bottomNavigationBar;

  const SpecificPostScreen({
    super.key,
    required this.postTopic,
    required this.nickname,
    required this.title,
    required this.content,
    required this.likes,
    required this.comments,
    required this.timestamp,
    required this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 다시 돌아갈 수 있는 홈페이지 버튼도 있으면 좋을 듯
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        elevation: 2,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              postTopic,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.red,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Hero(
              tag: 'title_$title',
              child: Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'By $nickname - ${timestamp.year}-${timestamp.month}-${timestamp.day}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              content,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                const Icon(Icons.favorite_border),
                const SizedBox(width: 4.0),
                Text('$likes'),
                const SizedBox(width: 10.0),
                const Icon(Icons.comment),
                const SizedBox(width: 4.0),
                Text('$comments'),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
