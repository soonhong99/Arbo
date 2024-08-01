import 'package:arbo_frontend/data/history_data.dart';
import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/data/user_data_provider.dart';
import 'package:arbo_frontend/design/paint_stroke.dart';
import 'package:arbo_frontend/roots/main_widget.dart';
import 'package:arbo_frontend/roots/root_screen.dart';
import 'package:arbo_frontend/screens/specific_comment_widget.dart';
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
  final UserDataProvider userDataProvider = UserDataProvider();
  late Future<void> _fetchDataFuture;
  bool deleteInSpecific = false;
  bool _sortByPopularity = true; // 초기 정렬 기준: 인기순

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!dataInitialized) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          setState(() {
            postData = args;
            postData['comments'] = postData['comments'] ?? [];
            dataInitialized = true;
          });
          _incrementViewCount();
          checkIfUserLiked();
          _checkIfPostOwner();
          _sortComments();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!dataInitialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        postData = args;
        postData['comments'] = postData['comments'] ?? [];
        _incrementViewCount();
        checkIfUserLiked();
        _checkIfPostOwner();
        _sortComments();
        dataInitialized = true;
        setState(() {});
      }
    }
  }

  Future<void> _toggleCommentHeart(String commentId) async {
    if (currentLoginUser == null) {
      _showLoginPopup();
      return;
    }

    final commentIndex =
        postData['comments'].indexWhere((c) => c['commentId'] == commentId);
    if (commentIndex == -1) return;

    final comment = postData['comments'][commentIndex];
    final hasLiked =
        comment['likedBy']?.contains(currentLoginUser!.uid) ?? false;
    final commentOwnerUserId = comment['userId']; // 새로 추가된 필드

    // 댓글 작성자가 아닌 경우에만 receivedCommentsHearts를 업데이트
    if (currentLoginUser!.uid != commentOwnerUserId) {
      DocumentReference commentOwnerRef =
          firestore_instance.collection('users').doc(commentOwnerUserId);

      if (hasLiked) {
        comment['hearts'] = (comment['hearts'] ?? 1) - 1;
        comment['likedBy'].remove(currentLoginUser!.uid);

        // receivedCommentsHearts 감소
        await commentOwnerRef.get().then((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>?;
            int currentHearts = data?['receivedCommentsHearts'] ?? 1;
            commentOwnerRef
                .update({'receivedCommentsHearts': currentHearts - 1});
          }
        });
      } else {
        comment['hearts'] = (comment['hearts'] ?? 0) + 1;
        comment['likedBy'] = (comment['likedBy'] ?? [])
          ..add(currentLoginUser!.uid);

        // receivedCommentsHearts 증가
        await commentOwnerRef.get().then((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>?;
            int currentHearts = data?['receivedCommentsHearts'] ?? 0;
            commentOwnerRef
                .update({'receivedCommentsHearts': currentHearts + 1});
          } else {
            // 문서가 존재하지 않는 경우, 새로 생성
            commentOwnerRef
                .set({'receivedCommentsHearts': 1}, SetOptions(merge: true));
          }
        });
      }
    } else {
      // 댓글 작성자가 자신의 댓글에 하트를 누르는 경우
      if (hasLiked) {
        comment['hearts'] = (comment['hearts'] ?? 1) - 1;
        comment['likedBy'].remove(currentLoginUser!.uid);
      } else {
        comment['hearts'] = (comment['hearts'] ?? 0) + 1;
        comment['likedBy'] = (comment['likedBy'] ?? [])
          ..add(currentLoginUser!.uid);
      }
    }

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postData['postId'])
        .update({'comments': postData['comments']});

    setState(() {});
    _sortComments();
  }

  void _sortComments() {
    if (_sortByPopularity) {
      postData['comments'].sort((a, b) {
        int heartsA = a['hearts'] ?? 0;
        int heartsB = b['hearts'] ?? 0;
        return heartsB.compareTo(heartsA);
      });
    } else {
      postData['comments'].sort((a, b) {
        Timestamp timestampA = a['timestamp'] as Timestamp;
        Timestamp timestampB = b['timestamp'] as Timestamp;
        return timestampB.compareTo(timestampA);
      });
    }
    setState(() {});
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

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RootScreen()),
      );

      page_location = 0;

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
    DocumentReference postOwnerRef =
        firestore_instance.collection('users').doc(postData['postOwnerId']);

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
      try {
        await postOwnerRef.get().then((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>?;

            int currentHearts = data?['receivedPostHearts'] ?? 0;
            if (_hasUserLiked) {
              // User is unliking, decrease the count
              postOwnerRef.update({'receivedPostHearts': currentHearts - 1});
            } else {
              // User is liking, increase the count
              postOwnerRef.update({'receivedPostHearts': currentHearts + 1});
            }
          } else {
            // Document doesn't exist, create it with initial value
            postOwnerRef
                .set({'receivedPostHearts': 1}, SetOptions(merge: true));
          }
        });
      } catch (e) {
        print('Error updating receivedPostHearts: $e');
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
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just before';
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
          painter: PathPainter(userPaintBackGround),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: Icon(_areCommentsVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      label: Text(_areCommentsVisible
                          ? 'Hide Comments'
                          : 'View Comments'),
                      onPressed: () {
                        setState(() {
                          _areCommentsVisible = !_areCommentsVisible;
                        });
                      },
                    ),
                    DropdownButton<bool>(
                      value: _sortByPopularity,
                      icon: const Icon(Icons.sort),
                      underline: Container(),
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _sortByPopularity = newValue;
                            _sortComments();
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text('Popular',
                              style: TextStyle(color: Colors.blue)),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Recent',
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              if (_areCommentsVisible)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: postData['comments'].length,
                  itemBuilder: (context, index) {
                    final comment = postData['comments'][index];
                    return CommentWidget(
                      comment: comment,
                      onHeartPressed: () =>
                          _toggleCommentHeart(comment['commentId']),
                      currentUserId: currentLoginUser?.uid,
                      onReplyPressed: (commentId) {
                        if (currentLoginUser == null) {
                          _showLoginPopup();
                        } else {
                          _showReplyDialog(commentId);
                        }
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: BotNaviWidget(
        postData: postData,
        refreshDataCallback: () {},
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
