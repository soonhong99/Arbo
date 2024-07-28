import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/data/user_data_provider.dart';
import 'package:arbo_frontend/design/paint_stroke.dart';
import 'package:arbo_frontend/screens/edit_post_screen.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/bot_navi_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/heart_animation_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  bool _areCommentsVisible = false;
  bool animationCompleted = false;
  final Map<String, bool> _commentToggleState = {};

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
      postData['comments'] =
          postData['comments'] ?? []; // Ensure comments is not null
      _incrementViewCount(); // Increment view count when the screen is accessed
      checkIfUserLiked();
      _checkIfPostOwner();
      dataInitialized = true;
    }
  }

  Future<void> deletePost() async {
    bool? confirmDelete = await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('게시글 삭제'),
          content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text('아니오'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('예'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    // 사용자가 대화 상자를 닫거나 '아니오'를 선택한 경우
    if (confirmDelete != true) {
      return; // 함수 종료
    }

    // 여기서부터는 사용자가 '예'를 선택한 경우의 로직
    try {
      // 로딩 인디케이터 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Firebase에서 게시글 삭제
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postData['postId'])
          .delete();

      // 로딩 인디케이터 닫기
      Navigator.of(context).pop();

      // 삭제 완료 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다!')),
      );

      // 현재 화면 닫기
      // Navigator.of(context).pop();

      // 게시글 목록 새로고침 (이 부분은 앱의 구조에 따라 다르게 구현해야 할 수 있습니다)
      // _refreshData();
    } catch (e) {
      // 오류 발생 시 로딩 인디케이터 닫기
      Navigator.of(context).pop();

      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _incrementViewCount() async {
    try {
      final postRef =
          firestore_instance.collection('posts').doc(postData['postId']);
      await postRef.update({'visitedUser': FieldValue.increment(1)});
      setState(() {
        postData['visitedUser'] = postData['visitedUser'] + 1;
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  void checkIfUserLiked() async {
    try {
      if (currentLoginUser == null) return;
      if (firstSpecificPostTouch) {
        likedPosts = loginUserData!['하트 누른 게시물'] ?? [];
        firstSpecificPostTouch = false;
      }
      setState(() {
        _hasUserLiked = likedPosts.contains(postData['postId']);
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
    final alertHeart = {
      'heartTimestamp': Timestamp.now().toDate().toIso8601String(), // 변경된 부분
      'postId': postData['postId'],
      'userId': currentLoginUser!.uid,
      'nickname': nickname,
      'title': postData['title'],
    };

    DocumentReference userRef =
        firestore_instance.collection('users').doc(userUid);
    DocumentReference heartRef =
        firestore_instance.collection('posts').doc(postData['postId']);
    if (currentLoginUser!.uid != postData['postOwnerId']) {
      try {
        await firestore_instance
            .collection('users')
            .doc(postData['postOwnerId'])
            .update({
          'alertMap.alertHeart': FieldValue.arrayUnion([alertHeart])
        });
      } catch (e) {
        print('cant go alert: $e');
      }
    }

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
        likedPosts.add(postData['postId']);
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

    final alertComment = {
      'comment': comment,
      'commentTimestamp': Timestamp.now().toDate().toIso8601String(),
      'postId': postData['postId'],
      'userId': currentLoginUser!.uid,
      'nickname': nickname,
      'title': postData['title'],
    };
    dataChanged = true;
    DocumentReference postRef =
        firestore_instance.collection('posts').doc(postData['postId']);

    final newComment = {
      'commentId': UniqueKey().toString(),
      'comment': comment,
      'timestamp': Timestamp.now(),
      'userId': currentLoginUser!.uid,
      'nickname': nickname, // Include nickname
      'replies': [],
    };
    if (currentLoginUser!.uid != postData['postOwnerId']) {
      try {
        await firestore_instance
            .collection('users')
            .doc(postData['postOwnerId'])
            .update({
          'alertMap.alertComment': FieldValue.arrayUnion([alertComment])
        });
      } catch (e) {
        print('cannot alert comment: $e');
      }
    }

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
        firestore_instance.collection('posts').doc(postData['postId']);
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
              checkIfUserLiked();
              _checkIfPostOwner();
            });
          },
        );
      },
    );
  }

  void _navigateToEditPost() async {
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

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('yyyy-MM-dd').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  @override
  Widget build(BuildContext context) {
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
        automaticallyImplyLeading: false,
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
                  const SizedBox(width: 8.0),
                  if (_isPostOwner)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: deletePost,
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
                  hintText: 'Please enter your comments.',
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
                          ? 'Hide ${countTotalComments(comments)} Comments'
                          : 'View ${countTotalComments(comments)} Comments',
                    ),
                  ),
                ),
              ],
              if (_areCommentsVisible)
                ...(postData['comments'] as List).reversed.map((comment) {
                  bool hasReplies = comment['replies'] != null &&
                      comment['replies'].isNotEmpty;
                  int replyCount = comment['replies']?.length ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    comment['nickname'][0].toUpperCase(),
                                    style: TextStyle(color: Colors.blue[800]),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            comment['nickname'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatTimestamp(
                                                comment['timestamp']
                                                    as Timestamp),
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(comment['comment']),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  icon: Icon(
                                    _commentToggleState[comment['commentId']] ??
                                            false
                                        ? Icons.arrow_drop_up
                                        : Icons.arrow_drop_down,
                                    color: Colors.blue,
                                  ),
                                  label: Text(
                                    hasReplies
                                        ? 'View $replyCount ${replyCount == 1 ? 'reply' : 'replies'}'
                                        : 'No replies',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                  onPressed: hasReplies
                                      ? () {
                                          setState(() {
                                            _commentToggleState[
                                                    comment['commentId']] =
                                                !(_commentToggleState[
                                                        comment['commentId']] ??
                                                    false);
                                          });
                                        }
                                      : null,
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.reply,
                                      color: Colors.green),
                                  label: const Text('Reply',
                                      style: TextStyle(color: Colors.green)),
                                  onPressed: () {
                                    if (currentLoginUser == null) {
                                      _showLoginPopup();
                                      return;
                                    }
                                    _showReplyDialog(comment['commentId']);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (hasReplies &&
                          (_commentToggleState[comment['commentId']] ?? false))
                        Container(
                          margin: const EdgeInsets.only(left: 40, bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: (comment['replies'] as List)
                                .reversed
                                .map<Widget>((reply) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.green[100],
                                      child: Text(
                                        reply['nickname'][0].toUpperCase(),
                                        style: TextStyle(
                                            color: Colors.green[800],
                                            fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                reply['nickname'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatTimestamp(
                                                    reply['timestamp']
                                                        as Timestamp),
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 10),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(reply['comment'],
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  );
                }),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: BotNaviWidget(
        postData: postData,
        refreshDataCallback: () {},
        onPreviousPage: () {},
      ),
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
