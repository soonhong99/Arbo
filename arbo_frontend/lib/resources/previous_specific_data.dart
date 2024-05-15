// previous_specific_data.dart
import 'package:flutter/material.dart';

class PreviousSpecificData {
  static Map<String, dynamic> previousSpecific = {
    'postTopic': '',
    'nickname': '',
    'title': '',
    'content': '',
    'likes': 0,
    'comments': 0,
    'timestamp': DateTime.now().toIso8601String(),
  };

  static void updateData({
    required String postTopic,
    required String nickname,
    required String title,
    required String content,
    required int likes,
    required int comments,
    required DateTime timestamp,
  }) {
    previousSpecific = {
      'postTopic': postTopic,
      'nickname': nickname,
      'title': title,
      'content': content,
      'likes': likes,
      'comments': comments,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
