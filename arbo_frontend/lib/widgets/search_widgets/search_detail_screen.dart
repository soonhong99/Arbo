import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/design/paint_stroke.dart';
import 'package:arbo_frontend/screens/edit_post_screen.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/heart_animation_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchDetailScreen extends StatefulWidget {
  final String postId;

  const SearchDetailScreen({super.key, required this.postId});

  @override
  State<SearchDetailScreen> createState() => _SearchDetailScreenState();
}

class _SearchDetailScreenState extends State<SearchDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _hasUserLiked = false;
  bool _isPostOwner = false;
  late Map<String, dynamic> postData;
  bool dataInitialized = false;
  bool _areCommentsVisible = false;
  bool animationCompleted = false;

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
      _fetchPostDetails().then((data) {
        setState(() {
          postData = data;
          postData['comments'] = postData['comments'] ?? [];
          _incrementViewCount();
          _checkIfUserLiked();
          _checkIfPostOwner();
          dataInitialized = true;
        });
      });
    }
  }

  Future<Map<String, dynamic>> _fetchPostDetails() async {
    final doc =
        await firestore_instance.collection('posts').doc(widget.postId).get();
    return doc.data()!;
  }

  Future<void> _incrementViewCount() async {
    try {
      final postRef = firestore_instance
          .collection('posts')
          // .doc(widget.postId);
          .doc(widget.postId);
      await postRef.update({'visitedUser': FieldValue.increment(1)});
      setState(() {
        postData['visitedUser'] = postData['visitedUser'] + 1;
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  void _checkIfUserLiked() async {
    try {
      if (currentLoginUser == null) return;
      if (firstSpecificPostTouch) {
        likedPosts = loginUserData!['하트 누른 게시물'] ?? [];
        firstSpecificPostTouch = false;
      }
      setState(() {
        _hasUserLiked = likedPosts.contains(widget.postId);
        dataChanged = true;
      });
    } catch (e) {
      // unexpected null value error
      print('error in check if user liked: $e');
    }
  }

  Future<void> _checkIfPostOwner() async {
    try {
      if (currentLoginUser == null) return;
      setState(() {
        _isPostOwner = currentLoginUser!.uid == postData['userId'];
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
        firestore_instance.collection('users').doc(userUid);
    DocumentReference heartRef =
        firestore_instance.collection('posts').doc(widget.postId);

    if (_hasUserLiked) {
      await userRef.update({
        '하트 누른 게시물': FieldValue.arrayRemove([widget.postId])
      });
      await heartRef.update({'hearts': FieldValue.increment(-1)});
      setState(() {
        _hasUserLiked = false;
        postData['hearts']--;
      });
    } else {
      await userRef.update({
        '하트 누른 게시물': FieldValue.arrayUnion([widget.postId])
      });
      await heartRef.update({'hearts': FieldValue.increment(1)});
      setState(() {
        _hasUserLiked = true;
        likedPosts.add(widget.postId);
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
        firestore_instance.collection('posts').doc(widget.postId);

    final newComment = {
      'commentId': UniqueKey().toString(),
      'comment': comment,
      'timestamp': Timestamp.now(),
      'userId': currentLoginUser!.uid,
      'nickname': nickname, // Include nickname
      'replies': [],
    };

    await postRef.update({
      'comments': FieldValue.arrayUnion([newComment])
    });

    setState(() {
      postData['comments'].insert(0, newComment);
    });

    _commentController.clear();
  }

  Future<void> addReply(String comment, String parentCommentId) async {
    if (comment.isEmpty) return;

    if (currentLoginUser == null) {
      _showLoginPopup();
      return;
    }

    final newReply = {
      'commentId': UniqueKey().toString(),
      'comment': comment,
      'timestamp': Timestamp.now(),
      'userId': currentLoginUser!.uid,
      'nickname': nickname, // Include nickname
    };

    setState(() {
      for (var c in postData['comments']) {
        if (c['commentId'] == parentCommentId) {
          c['replies'].insert(0, newReply);
          break;
        }
      }
    });

    DocumentReference postRef =
        firestore_instance.collection('posts').doc(widget.postId);
    await postRef.update({'comments': postData['comments']});

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

  void _navigateToEditPost() async {
    // Implement navigation to the post edit screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostScreen(postData: postData),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        postData['topic'] = result['topic'];
        postData['title'] = result['title'];
        postData['content'] = result['content'];
      });

      // Firestore 업데이트
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postData['postId'])
          .update({
        'topic': result['topic'],
        'title': result['title'],
        'content': result['content'],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!dataInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final comments = postData['comments'] ?? [];
    DateTime postTime = (postData['timestamp'] as Timestamp).toDate();
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.7; // 70% of the screen width

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        elevation: 2,
        foregroundColor: Colors.black,
      ),
      body: Stack(children: [
        CustomPaint(
          painter: StrokePainter(userPaintBackGround),
          size: Size.infinite,
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    postData['topic'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.red,
                    ),
                  ),
                  const Spacer(), // This will push the IconButton to the right
                  if (_isPostOwner)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _navigateToEditPost,
                    ),
                ],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'By ${postData['nickname']} - ${postTime.year}-${postTime.month}-${postTime.day}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Views: ${postData['visitedUser']}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Center(
                child: Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: postData['designedPicture']
                      .map<Widget>((imageUrl) => GestureDetector(
                            onDoubleTap: () {
                              _updateHearts();
                              if (_hasUserLiked == false &&
                                  currentLoginUser != null) {
                                animationCompleted = true;
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: imageSize,
                                  height: imageSize,
                                  color: Colors.grey[300], // Placeholder color
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print(error);
                                      return const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      );
                                    },
                                  ),
                                ),
                                Opacity(
                                  opacity: animationCompleted ? 1 : 0,
                                  child: HeartAnimationWidget(
                                      isAnimating: animationCompleted,
                                      duration:
                                          const Duration(milliseconds: 700),
                                      onEnd: () => setState(
                                            () => animationCompleted = false,
                                          ),
                                      child: const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 100.0,
                                      )),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
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
                  Text('${countTotalComments(comments)}'),
                ],
              ),
              Text(
                postData['content'],
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요.',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () =>
                        _addComment(_commentController.text), // Add this line
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              if (dataInitialized) ...[
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _areCommentsVisible = !_areCommentsVisible; // Toggle
                      });
                    },
                    child: Text(
                      _areCommentsVisible
                          ? '댓글 ${comments.length}개 접기'
                          : '댓글 ${comments.length}개 보기',
                    ),
                  ),
                ),
              ],
              if (_areCommentsVisible)
                ...comments.map((comment) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                            '${comment['nickname']} - ${comment['comment']}'),
                        subtitle: Text((comment['timestamp'] as Timestamp)
                            .toDate()
                            .toString()),
                        trailing: IconButton(
                          icon: const Icon(Icons.reply),
                          onPressed: () =>
                              _showReplyDialog(comment['commentId']),
                        ),
                      ),
                      ...comment['replies'].map<Widget>((reply) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: ListTile(
                            title: Text(
                                '${reply['nickname']} - ${reply['comment']}'),
                            subtitle: Text((reply['timestamp'] as Timestamp)
                                .toDate()
                                .toString()),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
            ],
          ),
        ),
      ]),
    );
  }

  void _showReplyDialog(String parentId) {
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
                addReply(replyController.text, parentId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
