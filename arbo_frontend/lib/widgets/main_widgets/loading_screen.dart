import 'package:arbo_frontend/widgets/search_widgets/search_detail_screen.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final String postId;

  const LoadingScreen({super.key, required this.postId});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    // 데이터가 Firestore에 완전히 저장되도록 잠시 대기
    await Future.delayed(const Duration(seconds: 2));

    // 컨텍스트가 여전히 유효한지 확인
    if (!mounted) return;

    // SearchDetailScreen으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SearchDetailScreen(postId: widget.postId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading your new post...'),
          ],
        ),
      ),
    );
  }
}
