import 'package:arbo_frontend/resources/fetch_data.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart'; // Import the LoginPopupWidget
import 'package:arbo_frontend/widgets/main_widgets/bot_navi_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SpecificPostScreen extends StatefulWidget {
  static const routeName = '/specific_post';
  final String postId;
  final String postTopic;
  final String nickname;
  final String title;
  final String content;
  final int hearts;
  final List<Map<String, dynamic>> comments;
  final DateTime timestamp;
  final VoidCallback? onheartClicked;

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
    this.onheartClicked,
  });

  factory SpecificPostScreen.fromMap(Map<String, dynamic> map) {
    return SpecificPostScreen(
      postId: map['postId'],
      postTopic: map['postTopic'],
      nickname: map['nickname'],
      title: map['title'],
      content: map['content'],
      hearts: map['hearts'],
      comments: List<Map<String, dynamic>>.from(map['comments']),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  State<SpecificPostScreen> createState() => SpecificPostScreenState();
}

class SpecificPostScreenState extends State<SpecificPostScreen> {
  final TextEditingController _commentController = TextEditingController();
  late int _hearts;
  late List<Map<String, dynamic>> _comments;
  bool _hasUserLiked = false;

  @override
  void initState() {
    super.initState();
    _hearts = widget.hearts;
    _comments = List.from(widget.comments);
    _checkIfUserLiked();
  }

  Future<void> _checkIfUserLiked() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentReference postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    DocumentSnapshot snapshot =
        await postRef.collection('hearts').doc(user.uid).get();

    setState(() {
      _hasUserLiked = snapshot.exists;
    });
  }

  void _updateHearts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginPopup();
      return;
    }

    DocumentReference postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    if (_hasUserLiked) {
      // If the user has already liked the post, remove the like
      await postRef.collection('hearts').doc(user.uid).delete();
      await postRef.update({'hearts': _hearts - 1});

      setState(() {
        _hearts -= 1;
        _hasUserLiked = false;
      });
    } else {
      // If the user hasn't liked the post, add the like
      await postRef.collection('hearts').doc(user.uid).set({'liked': true});
      await postRef.update({'hearts': _hearts + 1});

      setState(() {
        _hearts += 1;
        _hasUserLiked = true;
      });
    }

    widget.onheartClicked?.call();
  }

  Future<void> _addComment(String comment) async {
    if (comment.isEmpty) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginPopup();
      return;
    }

    DocumentReference postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    final newComment = {
      'comment': comment,
      'timestamp': Timestamp.now(),
      'userId': user.uid,
    };

    await postRef.collection('comments').add(newComment);

    setState(() {
      _comments.insert(0, newComment);
    });

    _commentController.clear();
  }

  Future<void> fetchSpecificData() async {
    FetchData fetchData = FetchData();
    Map<String, dynamic> postData =
        await fetchData.fetchPostAndCommentsData(widget.postId);

    DocumentSnapshot post = postData['post'];
    List<DocumentSnapshot> comments = postData['comments'];

    setState(() {
      _hearts = post['hearts'];
      _comments = comments
          .map((comment) => {
                'comment': comment['comment'],
                'timestamp': comment['timestamp'],
                'userId': comment['userId'],
              })
          .toList();
    });
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

  void _showLoginPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LoginPopupWidget(
          onLoginSuccess: (User user) {
            setState(() {});
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const SizedBox(height: 20),
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
                  icon: Icon(
                    _hasUserLiked ? Icons.favorite : Icons.favorite_border,
                  ),
                  onPressed: _updateHearts,
                ),
                const SizedBox(width: 4.0),
                Text('$_hearts'),
                const SizedBox(width: 10.0),
                const Icon(Icons.comment),
                const SizedBox(width: 4.0),
                Text('${_comments.length}'),
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
              return ListTile(
                title: Text(comment['comment']),
                subtitle: Text(
                  (comment['timestamp'] as Timestamp).toDate().toString(),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: const BotNaviWidget(),
    );
  }
}
