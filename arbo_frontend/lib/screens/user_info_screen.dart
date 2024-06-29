import 'package:arbo_frontend/resources/user_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoScreen extends StatefulWidget {
  final User? user;
  static const routeName = '/user-info';

  const UserInfoScreen({super.key, required this.user});

  @override
  _UserInfoWidgetState createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _nicknameController.text = nickname;
    });
  }

  Future<void> _updateNickname() async {
    setState(() {
      _isLoading = true;
    });
    await firestore_instance
        .collection('users')
        .doc(widget.user!.uid)
        .update({'닉네임': _nicknameController.text});
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('닉네임이 변경되었습니다.')),
    );
  }

  Future<void> _updatePassword() async {
    setState(() {
      _isLoading = true;
    });
    await widget.user!.updatePassword(_passwordController.text);
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('이메일: ${widget.user!.email}'),
                  Text('UID: ${widget.user!.uid}'),
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    '개인정보 변경',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _updateNickname,
                    child: const Text('닉네임 변경'),
                  ),
                  ElevatedButton(
                    onPressed: _updatePassword,
                    child: const Text('비밀번호 변경'),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    '활동 내역',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<QuerySnapshot>(
                    future: firestore_instance
                        .collection('posts')
                        .where('userId', isEqualTo: widget.user!.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return const Text('오류가 발생했습니다.');
                      } else if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Text('작성한 글이 없습니다.');
                      } else {
                        return ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: snapshot.data!.docs.map((doc) {
                            return ListTile(
                              title: Text(doc['title']),
                              subtitle: Text(doc['content']),
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
