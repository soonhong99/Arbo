import 'package:arbo_frontend/widgets/main_widgets/bot_navi_widget.dart';
import 'package:flutter/material.dart';
import 'package:arbo_frontend/resources/history_data.dart';

// 무슨 댓글인지, 하트를 누르면 하트 수가 늘어나고, 댓글을 쓸 수 있게 하는 기능 구현
class SpecificPostScreen extends StatelessWidget {
  static const routeName = '/specific_post';

  final String postTopic;
  final String nickname;
  final String title;
  final String content;
  final int likes;
  final int comments;
  final DateTime timestamp;

  const SpecificPostScreen({
    super.key,
    required this.postTopic,
    required this.nickname,
    required this.title,
    required this.content,
    required this.likes,
    required this.comments,
    required this.timestamp,
  });

  // 인자값을 갖고오는 생성자
  factory SpecificPostScreen.fromMap(Map<String, dynamic> map) {
    return SpecificPostScreen(
      postTopic: map['postTopic'],
      nickname: map['nickname'],
      title: map['title'],
      content: map['content'],
      likes: map['likes'],
      comments: map['comments'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postTopic': postTopic,
      'nickname': nickname,
      'title': title,
      'content': content,
      'likes': likes,
      'comments': comments,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 다시 돌아갈 수 있는 홈페이지 버튼도 있으면 좋을 듯
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        elevation: 2,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
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
      bottomNavigationBar: const BotNaviWidget(),
    );
  }
}
