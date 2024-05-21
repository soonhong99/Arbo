import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPopupWidget extends StatefulWidget {
  final Function(User) onLoginSuccess;

  const LoginPopupWidget({super.key, required this.onLoginSuccess});

  @override
  _LoginPopupWidgetState createState() => _LoginPopupWidgetState();
}

class _LoginPopupWidgetState extends State<LoginPopupWidget> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void validate() {
    if (emailController.text.trim() == '' ||
        passwordController.text.trim() == '') {
      return;
    }

    setState(() {
      isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2)).then((value) {
      setState(() {
        isLoading = false;
        signIn();
      });
    });
  }

  void signIn() {
    try {
      FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim())
          .then((value) {
        widget.onLoginSuccess(value.user!);
        Navigator.of(context).pop();
      });
    } catch (e) {
      debugPrint('에러: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('로그인'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'example@example.com',
              ),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child:
              isLoading ? const CircularProgressIndicator() : const Text('로그인'),
          onPressed: () {
            if (!isLoading) {
              validate();
            }
          },
        ),
        TextButton(
          child: const Text('회원가입'),
          onPressed: () {
            // Handle sign up navigation
          },
        ),
      ],
    );
  }
}
