import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/data/user_data_provider.dart';
import 'package:arbo_frontend/design/paint_stroke.dart';
import 'package:arbo_frontend/roots/root_screen.dart';
import 'package:arbo_frontend/screens/answering_post_screen.dart';
import 'package:arbo_frontend/screens/edit_post_screen.dart';
import 'package:arbo_frontend/screens/specific_comment_widget.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/heart_animation_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final Map<String, bool> _commentToggleState = {};
  final UserDataProvider userDataProvider = UserDataProvider();
  late Future<void> _fetchDataFuture;
  bool deleteInSpecific = false;
  bool _sortByPopularity = true; // 초기 정렬 기준: 인기순
  bool canApprove = false;
  List<Map<String, dynamic>> answeringPosts = [];
  final Map<String, bool> _answerCommentsVisibility = {};

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!dataInitialized) {
          _fetchPostDetails().then(
            (data) {
              setState(
                () {
                  postData = data;
                  postData['comments'] = postData['comments'] ?? [];
                  _incrementViewCount();
                  _checkIfUserLiked();
                  _checkIfPostOwner();
                  _sortComments();
                  _checkIfCanApprove();
                  _fetchAnsweringPosts();
                  dataInitialized = true;
                },
              );
            },
          );
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!dataInitialized) {
      _fetchPostDetails().then(
        (data) {
          setState(
            () {
              postData = data;
              postData['comments'] = postData['comments'] ?? [];
              _incrementViewCount();
              _checkIfUserLiked();
              _checkIfPostOwner();
              _sortComments();
              _checkIfCanApprove();
              _fetchAnsweringPosts();
              dataInitialized = true;
            },
          );
        },
      );
    }
  }

  Future<void> _toggleGreatAnswer(String docId, bool isGreatAnswer) async {
    // if (currentLoginUser?.uid != postData['postOwnerId']) return;

    if (!_isPostOwner) return;

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('answeringPost')
          .doc(docId)
          .update({'greatAnswer': isGreatAnswer});

      // UI 업데이트
      setState(() {
        final answerIndex =
            answeringPosts.indexWhere((post) => post['docId'] == docId);
        if (answerIndex != -1) {
          answeringPosts[answerIndex]['greatAnswer'] = isGreatAnswer;
        }
      });

      if (isGreatAnswer) {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update({'status': 'clear'});

        // 로컬 상태 업데이트
        setState(() {
          postData['status'] = 'clear';
        });

        // 사용자에게 알림
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This post has been marked as clear!')),
        );
      }
    } catch (e) {
      print('Error toggling great answer: $e');
    }
  }

  Future<void> _fetchAnsweringPosts() async {
    final answersSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('answeringPost')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      answeringPosts = answersSnapshot.docs.map((doc) {
        final data = doc.data();
        data['imageUrls'] = (data['imageUrls'] as List<dynamic>?)
                ?.map((url) => url.toString())
                .toList() ??
            [];
        data['docId'] = doc.id; // 문서 ID 저장
        return data;
      }).toList();
    });
  }

  Widget _buildAnsweringPostWidget(Map<String, dynamic> answerPost) {
    String answerId = answerPost['docId'];
    bool areCommentsVisible = _answerCommentsVisibility[answerId] ?? false;
    final TextEditingController commentController = TextEditingController();

    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          border: answerPost['greatAnswer'] == true
              ? Border.all(
                  color: Colors.green,
                  width: 3,
                )
              : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: answerPost['greatAnswer'] == true
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (answerPost['greatAnswer'] == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "${postData['nickname']} choose this answer is great!!",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        answerPost['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    if (currentLoginUser?.uid == postData['postOwnerId'])
                      ElevatedButton.icon(
                        onPressed: () => _toggleGreatAnswer(
                          answerPost['docId'],
                          !answerPost['greatAnswer'],
                        ),
                        icon: Icon(answerPost['greatAnswer']
                            ? Icons.star
                            : Icons.star_border),
                        label: Text(answerPost['greatAnswer']
                            ? 'Great Answer'
                            : 'Mark as Great'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const Text(
                  'Content:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  answerPost['content'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: (answerPost['imageUrls'] as List<dynamic>?)
                          ?.map((url) => Image.network(url.toString(),
                              width: 100, height: 100, fit: BoxFit.cover))
                          .toList() ??
                      [],
                ),
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    Text(' ${answerPost['nickname']}'),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time, size: 16),
                    Text(' ${_formatTimestamp(answerPost['timestamp'])}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        answerPost['likedBy']
                                    ?.contains(currentLoginUser?.uid) ??
                                false
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () => _toggleAnswerHeart(answerPost['docId']),
                    ),
                    Text('${answerPost['hearts'] ?? 0}'),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      icon: Icon(
                        areCommentsVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.blue, // 아이콘 색상 설정 (선택사항)
                      ),
                      label: Text(
                        areCommentsVisible ? 'Hide Comments' : 'View Comments',
                        style: const TextStyle(
                            color: Colors.blue), // 텍스트 색상 설정 (선택사항)
                      ),
                      onPressed: () {
                        setState(() {
                          areCommentsVisible = !areCommentsVisible;
                        });
                      },
                    ),
                    Text(
                      '${(answerPost['comments'] as List?)?.length ?? 0} comment in this answer',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (areCommentsVisible) ...[
                  const Divider(),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Please enter your comments.',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (currentLoginUser == null) {
                            _showLoginPopup();
                            return;
                          }
                          _addAnswerComment(
                              answerPost['docId'], commentController.text);
                          commentController.clear();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(answerPost['comments'] as List? ?? [])
                      .map((comment) => comment as Map<String, dynamic>)
                      .toList()
                      .reversed
                      .map((comment) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: 12.0), // 댓글 사이 간격 추가
                            child: Card(
                              elevation: 2, // 그림자 효과 추가
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person,
                                            size: 18,
                                            color: Colors.blue), // 사용자 아이콘
                                        const SizedBox(width: 8),
                                        Text(
                                          '${comment['nickname']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(Icons.access_time,
                                            size: 16,
                                            color: Colors.grey[600]), // 시간 아이콘
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTimestamp(
                                              comment['timestamp']),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.chat_bubble_outline,
                                            size: 18,
                                            color: Colors.green), // 댓글 내용 아이콘
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            comment['text'],
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                ],
                const Divider(),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.support_agent, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Supporter Answer',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _toggleAnswerHeart(String answerPostId) async {
    if (currentLoginUser == null) {
      _showLoginPopup();
      return;
    }

    final answerRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('answeringPost')
        .doc(answerPostId);

    final answerDoc = await answerRef.get();
    final answerData = answerDoc.data() as Map<String, dynamic>;

    final List<String> likedBy = List<String>.from(answerData['likedBy'] ?? []);
    final bool isLiked = likedBy.contains(currentLoginUser!.uid);

    if (isLiked) {
      likedBy.remove(currentLoginUser!.uid);
      await answerRef.update({
        'hearts': FieldValue.increment(-1),
        'likedBy': likedBy,
      });
    } else {
      likedBy.add(currentLoginUser!.uid);
      await answerRef.update({
        'hearts': FieldValue.increment(1),
        'likedBy': likedBy,
      });
    }

    _fetchAnsweringPosts(); // Refresh the data
  }

  void _showAnswerCommentDialog(String docId) {
    if (currentLoginUser == null) {
      _showLoginPopup();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController commentController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(hintText: 'Enter your comment'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                _addAnswerComment(docId, commentController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addAnswerComment(String docId, String commentText) async {
    if (commentText.isEmpty) return;

    final comment = {
      'userId': currentLoginUser!.uid,
      'nickname': nickname,
      'text': commentText,
      'timestamp': Timestamp.now(),
    };
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('answeringPost')
          .doc(docId)
          .update({
        'comments': FieldValue.arrayUnion([comment]),
      });

      // 댓글 추가 후 상태 업데이트
      setState(() {
        _answerCommentsVisibility[docId] = true; // 댓글 가시성 상태 유지
      });

      // 새 댓글을 해당 답변 포스트의 댓글 목록 시작 부분에 추가
      final answerIndex =
          answeringPosts.indexWhere((post) => post['docId'] == docId);
      if (answerIndex != -1) {
        answeringPosts[answerIndex]['comments'] = [
          comment,
          ...?answeringPosts[answerIndex]['comments']
        ];
      }
    } catch (e) {
      print('answering comment error: $e');
    }

    await _fetchAnsweringPosts(); // Refresh the data
  }

  void _checkIfCanApprove() {
    setState(() {
      canApprove = nowSupporters &&
          (postData['hearts'] as int? ?? 0) >= 10 &&
          (postData['status'] as String? ?? '') == 'pending';
    });
  }

  Future<void> _approvePost() async {
    if (!canApprove) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({'status': 'approved'});

    setState(() {
      postData['status'] = 'approved';
      canApprove = false;
    });
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
        // .doc(postData['postId'])
        .doc(widget.postId)
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

  Future<Map<String, dynamic>> _fetchPostDetails() async {
    final doc =
        await firestore_instance.collection('posts').doc(widget.postId).get();
    return doc.data()!;
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
          .doc(widget.postId)
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

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RootScreen()),
      );
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
    final alertHeart = {
      'heartTimestamp': Timestamp.now().toDate().toIso8601String(), // 변경된 부분
      'postId': widget.postId,
      'userId': currentLoginUser!.uid,
      'nickname': nickname,
    };
    DocumentReference userRef =
        firestore_instance.collection('users').doc(userUid);
    DocumentReference heartRef =
        firestore_instance.collection('posts').doc(widget.postId);
    if (currentLoginUser!.uid != postData['userId']) {
      try {
        await firestore_instance
            .collection('users')
            .doc(postData['userId'])
            .update({
          'alertMap.alertHeart': FieldValue.arrayUnion([alertHeart])
        });
      } catch (e) {
        print('cant go alert: $e');
      }
    }

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

    final alertComment = {
      'comment': comment,
      'commentTimestamp': Timestamp.now().toDate().toIso8601String(),
      'postId': widget.postId,
      'userId': currentLoginUser!.uid,
      'nickname': nickname,
      'title': postData['title'],
    };
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
    if (currentLoginUser!.uid != postData['userId']) {
      try {
        await firestore_instance
            .collection('users')
            .doc(postData['userId'])
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
          // .doc(postData['postId'])
          .doc(widget.postId)
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
    if (!dataInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final comments = postData['comments'] ?? [];
    DateTime postTime = (postData['timestamp'] as Timestamp).toDate();
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.7; // 70% of the screen width

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 기본 뒤로 가기 버튼 제거
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        elevation: 2,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          tooltip: '검색결과로 돌아가기',
          onPressed: () => Navigator.pop(context),
        ),
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
                  if (canApprove)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Post approved!'),
                      onPressed: _approvePost,
                    ),
                  if (postData['status'] == 'approved' && nowSupporters)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Giving your own answer!'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AnsweringPostScreen(postId: widget.postId),
                          ),
                        );
                      },
                    ),
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
              const SizedBox(height: 24),
              ...answeringPosts.map((post) => Column(
                    children: [
                      _buildAnsweringPostWidget(post),
                      const SizedBox(height: 30), // 각 답변 포스트 사이에 간격 추가
                    ],
                  )),
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
