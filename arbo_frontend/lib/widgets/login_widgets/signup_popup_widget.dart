import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SignupPopupWidget extends StatelessWidget {
  const SignupPopupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('회원가입'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildTextField(label: '아이디', hintText: '한글, 영어, 숫자'),
            _buildTextField(label: '비밀번호', hintText: '한글, 영어, 숫자'),
            _buildTextField(label: '생년월일', hintText: '숫자만 입력하세요'),
            _buildTextField(label: '이름', hintText: '한글, 영어'),
            _buildTextField(label: '닉네임', hintText: '한글, 영어, 숫자'),
            _buildTextField(label: '이메일 주소', hintText: '한글, 영어, 숫자, 기호'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('회원가입'),
          onPressed: () {
            // 회원가입 버튼이 눌렸을 때의 동작 구현
          },
        ),
      ],
    );
  }
}

Widget _buildTextField({String? label, String? hintText}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
      ),
      // 입력 값이 유효한지 확인하는 코드를 추가해야 합니다.
    ),
  );
}
