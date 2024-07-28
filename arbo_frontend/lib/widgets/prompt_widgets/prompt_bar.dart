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
          child: TextButton(
            onPressed: onPromptTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Click and Try to solve your problems with your community!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
