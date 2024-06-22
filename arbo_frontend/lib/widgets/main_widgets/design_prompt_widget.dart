import 'package:flutter/material.dart';

class DesignPromptWidget extends StatelessWidget {
  final VoidCallback onPromptTap;

  const DesignPromptWidget({super.key, required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPromptTap,
      child: Hero(
        tag: 'designPrompt',
        child: TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '디자인 프롬프트 입력',
          ),
          readOnly: true,
          onTap: onPromptTap,
        ),
      ),
    );
  }
}
