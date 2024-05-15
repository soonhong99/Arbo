// previous_specific_data.dart

// 잠시 데이터들을 저장하는 보관소
class SpecificData {
  static Map<String, dynamic> specificData = {
    'postTopic': '',
    'nickname': '',
    'title': '',
    'content': '',
    'likes': 0,
    'comments': 0,
    'timestamp': DateTime.now().toIso8601String(),
  };

  // previous Specific Map에 내용들 추가.
  static void updateData({
    required String postTopic,
    required String nickname,
    required String title,
    required String content,
    required int likes,
    required int comments,
    required DateTime timestamp,
  }) {
    specificData = {
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
