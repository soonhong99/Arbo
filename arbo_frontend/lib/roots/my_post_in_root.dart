import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/data/user_data_provider.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/loading_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyPostsInRoot extends StatefulWidget {
  final String postsTitle;
  final String notLoginInfo;
  final bool mypost;
  const MyPostsInRoot({
    super.key,
    required this.postsTitle,
    required this.notLoginInfo,
    required this.mypost,
  });

  @override
  _MyPostsInRootState createState() => _MyPostsInRootState();
}

class _MyPostsInRootState extends State<MyPostsInRoot> {
  bool _isExpanded = false;
  List<Map<String, dynamic>> _localPosts = [];

  @override
  Widget build(BuildContext context) {
    Provider.of<UserDataProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: currentLoginUser != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.postsTitle,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (widget.mypost)
                    _buildPostsList(context)
                  else
                    _buildHeartsList(),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(widget.notLoginInfo),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return LoginPopupWidget(
                              onLoginSuccess: () {},
                            );
                          },
                        );
                      },
                      child: const Text('로그인'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLocalPostsList(String category) {
    if (category == 'liked') {
      _localPosts = likedPostsInRoot;
    } else if (category == 'mypost') {
      _localPosts = myPostsInRoot;
    }
    final displayPosts =
        _isExpanded ? _localPosts : _localPosts.take(3).toList();

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayPosts.length,
          itemBuilder: (context, index) {
            var post = displayPosts[index];
            return ListTile(
              title: Text(post['title']),
              subtitle: Text(post['content']),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LoadingScreen(postId: post['id']),
                    //SearchDetailScreen(postId: post['id']),
                  ),
                );
              },
            );
          },
        ),
        if (_localPosts.length > 3)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(_isExpanded ? '접기' : '더 보기'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeartsList() {
    if (loginInRoot && likedPostsInRoot.isNotEmpty) {
      return _buildLocalPostsList('liked');
    }
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _getLikedPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text('오류가 발생했습니다.');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('좋아한 글이 없습니다.');
        } else {
          final docs = snapshot.data!;
          likedPostsInRoot = docs
              .map((doc) => {
                    'id': doc.id,
                    'title': doc['title'],
                    'content': doc['content'],
                  })
              .toList();
          loginInRoot = true;
          return _buildLocalPostsList('liked');
        }
      },
    );
  }

  Future<List<DocumentSnapshot>> _getLikedPosts() async {
    List<DocumentSnapshot> likedPostDocs = [];

    // loginUserData에서 좋아한 게시물 ID 목록을 가져옵니다.
    List<String> likedPostIds =
        List<String>.from(loginUserData!['하트 누른 게시물'] ?? []);

    // 각 게시물 ID에 대해 Firestore에서 데이터를 가져옵니다.
    for (String postId in likedPostIds) {
      DocumentSnapshot doc =
          await firestore_instance.collection('posts').doc(postId).get();
      if (doc.exists) {
        likedPostDocs.add(doc);
      }
    }

    return likedPostDocs;
  }

  Widget _buildPostsList(BuildContext context) {
    if (loginInRoot && myPostsInRoot.isNotEmpty) {
      return _buildLocalPostsList('mypost');
    }
    return FutureBuilder<QuerySnapshot>(
      future: firestore_instance
          .collection('posts')
          .where('userId', isEqualTo: currentLoginUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text('오류가 발생했습니다.');
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('작성한 글이 없습니다.');
        } else {
          final docs = snapshot.data!.docs;

          myPostsInRoot = docs
              .map((doc) => {
                    'id': doc.id,
                    'title': doc['title'],
                    'content': doc['content'],
                  })
              .toList();
          loginInRoot = true;
          return _buildLocalPostsList('mypost');
        }
      },
    );
  }
}
