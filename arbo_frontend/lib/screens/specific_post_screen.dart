import 'package:arbo_frontend/resources/user_data.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/bot_navi_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SpecificPostScreen extends StatefulWidget {
  static const routeName = '/specific_post';

  const SpecificPostScreen({super.key});

  @override
  State<SpecificPostScreen> createState() => SpecificPostScreenState();
}

class SpecificPostScreenState extends State<SpecificPostScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _hasUserLiked = false;
  bool _isPostOwner = false;
  late Map<String, dynamic> postData;
  bool dataInitialized = false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!dataInitialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      postData = args;
      // Initialize other states based on postData if needed
      _checkIfUserLiked();
      _checkIfPostOwner();
      dataInitialized = true;
    }
  }

  Future<void> _checkIfUserLiked() async {
    try {
      if (currentLoginUser == null) return;

      if (loginUserData!.exists) {
        List<dynamic> likedPosts = loginUserData!['하트 누른 게시물'] ?? [];
        setState(() {
          _hasUserLiked = likedPosts.contains(postData['postId']);
          dataChanged = true;
        });
      }
    } catch (e) {
      // unexpected null value error
      print('error in check if user liked: $e');
    }
  }

  Future<void> _checkIfPostOwner() async {
    try {
      if (currentLoginUser == null) return;

      setState(() {
        _isPostOwner = currentLoginUser!.uid == postData['postOwnerId'];
      });
    } catch (e) {
      print('error in check if post owner');
    }
  }

  void _updateHearts() async {
    if (currentLoginUser == null) {
      _showLoginPopup();
      return;
    }

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userUid);

    DocumentReference heartRef =
        FirebaseFirestore.instance.collection('posts').doc(postData['postId']);

    if (_hasUserLiked) {
      await userRef.update({
        '하트 누른 게시물': FieldValue.arrayRemove([postData['postId']])
      });
      await heartRef.update({'hearts': FieldValue.increment(-1)});
      setState(() {
        _hasUserLiked = false;
        postData['hearts']--;
      });
    } else {
      await userRef.update({
        '하트 누른 게시물': FieldValue.arrayUnion([postData['postId']])
      });

      await heartRef.update({'hearts': FieldValue.increment(1)});
      setState(() {
        _hasUserLiked = true;
        postData['hearts']++;
      });
    }
  }

  Future<void> _addComment(String comment) async {
    if (comment.isEmpty) return;

    if (currentLoginUser == null) {
      _showLoginPopup();
      return;
    }
    dataChanged = true;
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('posts').doc(postData['postId']);

    // isreply와 parentComment, parentUserId를 이용해서 답글인지 확인한다.
    final newComment = {
      'comment': comment,
      'timestamp': Timestamp.now(),
      'userId': currentLoginUser!.uid,
      'parentId': 'null',
      'isReply': false,
      'parentComment': '',
    };
    await postRef.update({
      'comments': FieldValue.arrayUnion([newComment])
    });

    setState(() {
      postData['comments'].insert(0, newComment);
    });

    _commentController.clear();
  }

  Future<void> addReply(
      String comment, String parentComment, String parentId) async {
    if (comment.isEmpty) return;

    if (currentLoginUser == null) {
      _showLoginPopup();
      return;
    }

    final newReply = {
      'comment': comment,
      'timestamp': Timestamp.now(),
      'userId': currentLoginUser!.uid,
      'parentId': parentId,
      'isReply': true,
      'parentComment': parentComment,
    };

    setState(() {
      postData['comments'].insert(0, newReply);
    });

    DocumentReference postRef =
        FirebaseFirestore.instance.collection('posts').doc(postData['postId']);
    await postRef.update({
      'comments': FieldValue.arrayUnion([newReply])
    });

    _commentController.clear();
  }

  void _showLoginPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LoginPopupWidget(
          onLoginSuccess: () {
            setState(() {
              _checkIfUserLiked();
              _checkIfPostOwner();
            });
          },
        );
      },
    );
  }

  void _navigateToEditPost() {
    // Implement navigation to the post edit screen
  }

  @override
  Widget build(BuildContext context) {
    final comments = postData['comments'];
    DateTime postTime = (postData['timestamp'] as Timestamp).toDate();

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        elevation: 2,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: _isPostOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _navigateToEditPost,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              postData['topic'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Hero(
              tag: 'title_${postData['title']}',
              child: Text(
                postData['title'],
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'By ${postData['nickname']} - ${postTime.year}-${postTime.month}-${postTime.day}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              postData['content'],
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
                Text('${postData['hearts']}'),
                const SizedBox(width: 10.0),
                const Icon(Icons.comment),
                const SizedBox(width: 4.0),
                Text('${comments.length}'),
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
            ...comments.map((comment) {
              if (comment['isReply']) {
                return ListTile(
                  title: Text('Reply to ${comment['parentComment']}'),
                  subtitle: Text(comment['comment']),
                  trailing: Text(
                    (comment['timestamp'] as Timestamp).toDate().toString(),
                  ),
                );
              }
              return ListTile(
                title: Text(comment['comment']),
                subtitle: Text(
                  (comment['timestamp'] as Timestamp).toDate().toString(),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.reply),
                  onPressed: () => _showReplyDialog(
                      comment['parentId'], comment['parentComment']),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: BotNaviWidget(
        postData: postData,
      ),
    );
  }

  void _showReplyDialog(String parentId, String parentComment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController replyController = TextEditingController();
        return AlertDialog(
          title: const Text('Reply'),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(
              labelText: 'Enter your reply',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reply'),
              onPressed: () {
                addReply(replyController.text, parentComment, parentId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
