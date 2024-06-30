import 'package:flutter/material.dart';

class PromptBar extends StatelessWidget {
  final VoidCallback onPromptTap;

  const PromptBar({super.key, required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPromptTap,
      child: Hero(
        tag: 'designPrompt',
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              labelText: '당신의 고민을 지역사회와 함께 해결해보세요!',
              labelStyle: const TextStyle(color: Colors.white),
              suffixIcon: const Icon(Icons.arrow_forward, color: Colors.white),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 30),
            ),
            style: const TextStyle(color: Colors.white),
            readOnly: true,
            onTap: onPromptTap,
          ),
        ),
      ),
    );
  }
}
