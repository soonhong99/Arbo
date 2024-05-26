import 'package:arbo_frontend/widgets/main_widgets/bot_navi_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// 무슨 댓글인지, 하트를 누르면 하트 수가 늘어나고, 댓글을 쓸 수 있게 하는 기능 구현
class SpecificPostScreen extends StatefulWidget {
  static const routeName = '/specific_post';
  final String postId;
  final String postTopic;
  final String nickname;
  final String title;
  final String content;
  final int hearts;
  final List<dynamic> comments;
  final DateTime timestamp;

  const SpecificPostScreen({
    super.key,
    required this.postTopic,
    required this.nickname,
    required this.title,
    required this.content,
    required this.hearts,
    required this.comments,
    required this.timestamp,
    required this.postId,
  });

  // 인자값을 갖고오는 생성자
  factory SpecificPostScreen.fromMap(Map<String, dynamic> map) {
    return SpecificPostScreen(
      postId: map['postId'],
      postTopic: map['postTopic'],
      nickname: map['nickname'],
      title: map['title'],
      content: map['content'],
      hearts: map['hearts'],
      comments: map['comments'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  State<SpecificPostScreen> createState() => _SpecificPostScreenState();
}

class _SpecificPostScreenState extends State<SpecificPostScreen> {
  final TextEditingController _commentController = TextEditingController();
  late int _hearts;
  late List<dynamic> _comments;

  @override
  void initState() {
    super.initState();
    _hearts = widget.hearts;
    _comments = List.from(widget.comments);
  }

  Future<void> _updateHearts() async {
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    await postRef.update({'hearts': _hearts + 1});
    setState(() {
      _hearts += 1;
    });
  }

  Future<void> _addComment(String comment) async {
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    await postRef.collection('comments').add({
      'comment': comment,
      'timestamp': Timestamp.now(),
    });
    setState(() {
      _comments.add({'comment': comment, 'timestamp': Timestamp.now()});
    });
    _commentController.clear();
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': widget.postId,
      'postTopic': widget.postTopic,
      'nickname': widget.nickname,
      'title': widget.title,
      'content': widget.content,
      'hearts': widget.hearts,
      'comments': widget.comments,
      'timestamp': widget.timestamp.toIso8601String(),
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
              widget.postTopic,
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
              tag: 'title_${widget.title}',
              child: Text(
                widget.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'By ${widget.nickname} - ${widget.timestamp.year}-${widget.timestamp.month}-${widget.timestamp.day}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              widget.content,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: _updateHearts,
                ),
                const SizedBox(width: 4.0),
                Text('${widget.hearts}'),
                const SizedBox(width: 10.0),
                const Icon(Icons.comment),
                const SizedBox(width: 4.0),
                Text('${widget.comments.length}'),
              ],
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Add a comment',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _addComment(_commentController.text),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ..._comments.map((comment) {
              var commentData = comment as Map<String, dynamic>;
              return ListTile(
                title: Text(commentData['comment']),
                subtitle: Text((commentData['timestamp'] as Timestamp)
                    .toDate()
                    .toString()),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: const BotNaviWidget(),
    );
  }
}
