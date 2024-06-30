import 'package:arbo_frontend/data/prompt_history.dart';

class PostCreationHelper {
  final ChatHistory chatHistory;
  final Function(String) onSendMessage;

  PostCreationHelper({required this.chatHistory, required this.onSendMessage});

  Future<Map<String, String>> getSuggestions() async {
    final conversation = chatHistory.getFullConversation();
    final prompt =
        '''Based on the following conversations, suggest topics and titles for civic engagement posts in the community.
Examples include.\n
"AI: Hi there! I'm Chandler. How can I help you today?\n
User: i'm too thristy.. but I cant drink water anytime of it. I want to drink it a lot in every moment!\n
AI: I understand. Sometimes I feel the same way about things, like how I really want to go to the movies. But then I think, "Well, maybe I can do that tomorrow."\n
User: what? but I think that I want to this one, that can be great when I can take all of water in the park!\n
AI: That sounds amazing! A big refreshing gulp of water in the park. I can see why you'd want that. I think maybe if you just take a few sips right now, you'll feel less thirsty for a while and you can save that big gulp for later.\n
When the above format comes, we answer as follows.\n
topic: Establishment of public facilities\n
title: Install more drinking fountains\n
Below are the actual conversations between user and ai.:\n\n$conversation''';

    final response = await onSendMessage(prompt);

    // 응답을 파싱하여 주제와 제목을 추출합니다.
    // 실제 구현에서는 AI의 응답 형식에 따라 파싱 로직을 조정해야 합니다.
    final lines = response.split('\n');
    String topic = '';
    String title = '';

    for (var line in lines) {
      if (line.startsWith('Topic:')) {
        topic = line.substring(6).trim();
      } else if (line.startsWith('Title:')) {
        title = line.substring(6).trim();
      }
    }

    return {'topic': topic, 'title': title};
  }
}
