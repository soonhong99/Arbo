import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/data/user_data_provider.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyPostsInRoot extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);

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
                      postsTitle,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (mypost)
                    ..._buildFutureBuilders(context)
                  else
                    _buildOtherContent(),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(notLoginInfo),
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

  Widget _buildOtherContent() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('기타 컨텐츠를 여기에 표시할 수 있습니다.'),
    );
  }

  List<Widget> _buildFutureBuilders(BuildContext context) {
    return [
      FutureBuilder<QuerySnapshot>(
        future: firestore_instance
            .collection('posts')
            .where('userId', isEqualTo: currentLoginUser!.uid)
            .limit(3)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text('오류가 발생했습니다.');
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text('작성한 글이 없습니다.');
          } else {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                return ListTile(
                  title: Text(doc['title']),
                  subtitle: Text(doc['content']),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 게시물 상세 페이지로 이동
                  },
                );
              },
            );
          }
        },
      ),
      FutureBuilder<QuerySnapshot>(
        future: firestore_instance
            .collection('posts')
            .where('userId', isEqualTo: currentLoginUser!.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.hasError ||
              !snapshot.hasData) {
            return const SizedBox.shrink();
          }
          if (snapshot.data!.docs.length > 3) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // 전체 게시물 목록 페이지로 이동
                  },
                  child: const Text('더 보기'),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ];
  }
}
