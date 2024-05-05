import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

class KeyBoardTrigger extends StatefulWidget {
  const KeyBoardTrigger({
    required this.labelText,
    super.key,
  });

  final String labelText;

  @override
  State<KeyBoardTrigger> createState() => _KeyBoardTriggerState();
}

class _KeyBoardTriggerState extends State<KeyBoardTrigger> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,

      showCursor: true, // Dynamically control cursor visibility

      decoration: InputDecoration(
        counterText: '',
        labelText: widget.labelText,
        labelStyle: const TextStyle(color: Colors.black26),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(width: 1, color: Colors.black12),
        ),
      ),
    );
  }
}
