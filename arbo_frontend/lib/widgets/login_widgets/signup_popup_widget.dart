import 'package:arbo_frontend/screens/root_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPopupWidget extends StatefulWidget {
  const SignupPopupWidget({super.key});

  @override
  _SignupPopupWidgetState createState() => _SignupPopupWidgetState();
}

class _SignupPopupWidgetState extends State<SignupPopupWidget> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('회원가입'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildTextField(
                controller: _idController,
                label: '아이디',
                hintText: '한글, 영어, 숫자'),
            _buildTextField(
                controller: _passwordController,
                label: '비밀번호',
                hintText: '한글, 영어, 숫자',
                obscureText: true),
            _buildTextField(
                controller: _birthController,
                label: '생년월일',
                hintText: '숫자만 입력하세요'),
            _buildTextField(
                controller: _nameController, label: '이름', hintText: '한글, 영어'),
            _buildTextField(
                controller: _nicknameController,
                label: '닉네임',
                hintText: '한글, 영어, 숫자'),
            _buildTextField(
                controller: _emailController,
                label: '이메일 주소',
                hintText: '한글, 영어, 숫자, 기호'),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: signUp,
          child: const Text('회원가입'),
        ),
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      String? label,
      String? hintText,
      bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
        ),
        obscureText: obscureText,
      ),
    );
  }

  void signUp() async {
    setState(() {
      isLoading = true;
    });
    try {
      // 회원가입
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        '아이디': _idController.text,
        '생년월일': _birthController.text,
        '이름': _nameController.text,
        '닉네임': _nicknameController.text,
        '이메일 주소': _emailController.text,
      });

      setState(() {
        isLoading = false;
      });

      showResisterDialog();
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });

      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('에러: $e');
    }
  }

  void showResisterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원가입 성공'),
        content: const Text('회원가입이 성공적으로 완료되었습니다.'),
        actions: <Widget>[
          TextButton(
            child: const Text('확인'),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
