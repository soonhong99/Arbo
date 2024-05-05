import 'dart:math';

import 'package:flutter/material.dart';

class HangulWebKeyboardSetting extends StatefulWidget {
  final TextEditingController controller;
  final Widget child;

  const HangulWebKeyboardSetting({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  _HangulWebKeyboardSettingState createState() =>
      _HangulWebKeyboardSettingState();
}

class _HangulWebKeyboardSettingState extends State<HangulWebKeyboardSetting> {
  // ignore: constant_identifier_names
  static const List undetected_list = [
    " ",
    "`",
    "~",
    "!",
    "@",
    "#",
    "\$",
    "%",
    "^",
    "&",
    "*",
    "(",
    ")",
    "-",
    "_",
    "=",
    "+",
    "[",
    "]",
    "{",
    "}",
    "'",
    '"',
    ";",
    ":",
    "/",
    "?",
    ",",
    ".",
    "<",
    ">",
    "\\",
    "|",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "0"
  ];
  // ignore: constant_identifier_names
  static const List numberPad_list = [
    "Numpad Decimal",
    "Numpad Divide",
    "Numpad Multiply",
    "Numpad Subtract",
    "Numpad Add",
    "Numpad 0",
    "Numpad 1",
    "Numpad 2",
    "Numpad 3",
    "Numpad 4",
    "Numpad 5",
    "Numpad 6",
    "Numpad 7",
    "Numpad 8",
    "Numpad 9"
  ];
  // ignore: constant_identifier_names
  static const List numerPad_convert = [
    ".",
    "/",
    "*",
    "-",
    "+",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9"
  ];

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (RawKeyEvent event) async {
          if (event.runtimeType.toString() == 'RawKeyDownEvent') {
            String keydownText = event.data.logicalKey.keyLabel;
            int cursorPosition = widget.controller.selection.baseOffset;
            if (numberPad_list.contains(keydownText)) {
              keydownText =
                  numerPad_convert[numberPad_list.indexOf(keydownText)];
            }
            if (undetected_list.contains(keydownText)) {
              await Future.delayed(const Duration(milliseconds: 10));
              // ignore: non_constant_identifier_names
              List text_list = widget.controller.text.split("");
              try {
                if (text_list[cursorPosition] != keydownText) {
                  text_list.insert(cursorPosition, keydownText);
                  widget.controller.text = text_list.join();
                  widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: cursorPosition + 1));
                }
              } catch (e) {
                if (text_list[widget.controller.text.length - 1] !=
                    keydownText) {
                  widget.controller.text = widget.controller.text + keydownText;
                  widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: widget.controller.text.length));
                }
              }
            }
          }
        },
        child: widget.child);
  }
}
