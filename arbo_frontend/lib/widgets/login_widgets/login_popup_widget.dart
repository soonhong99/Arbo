import 'package:arbo_frontend/widgets/login_widgets/signup_popup_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginPopupWidget extends StatelessWidget {
  const LoginPopupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('로그인'),
      content: const SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                labelText: '이메일',
                hintText: 'example@example.com',
              ),
            ),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('로그인'),
          onPressed: () {
            // 여기에 로그인 기능을 구현하세요.
          },
        ),
        TextButton(
          child: const Text('회원가입'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const SignupPopupWidget(); // LoginPage 위젯을 반환합니다.
              },
            );
          },
        ),
      ],
    );
  }
}
