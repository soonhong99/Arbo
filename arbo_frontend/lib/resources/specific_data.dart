class SpecificData {
  static Map<String, dynamic> specificData = {
    'postId': '',
    'postTopic': '',
    'nickname': '',
    'title': '',
    'content': '',
    'hearts': 0,
    'comments': [],
    'timestamp': DateTime.now().toIso8601String(),
  };

  static void updateData({
    required String postId,
    required String postTopic,
    required String nickname,
    required String title,
    required String content,
    required int hearts,
    required List<Map<String, dynamic>> comments,
    required DateTime timestamp,
  }) {
    specificData = {
      'postId': postId,
      'postTopic': postTopic,
      'nickname': nickname,
      'title': title,
      'content': content,
      'hearts': hearts,
      'comments': comments,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
