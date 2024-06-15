import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyBoardTrigger extends StatelessWidget {
  const KeyBoardTrigger({
    super.key,
    required this.screenWidth,
  });

  final double screenWidth;
  final double formalScreenWidth = 600;
  // focus node to capture keyboard events
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Icon + 여백 크기: 100
      width: screenWidth - 250 < formalScreenWidth
          ? screenWidth - 250
          : formalScreenWidth,
      child: TextField(
        showCursor: true, // Dynamically control cursor visibility

        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(r'[0-9a-zA-Zㄱ-ㅎ가-힣\s]'),
          ),
        ],

        decoration: const InputDecoration(
          counterText: '',
          labelText: '검색할 게시글을 입력하세요',
          labelStyle: TextStyle(color: Colors.black26),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(width: 1, color: Colors.black12),
          ),
        ),
      ),
    );
  }
}
