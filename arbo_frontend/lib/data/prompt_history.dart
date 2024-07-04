import 'package:arbo_frontend/widgets/prompt_widgets/chat_message.dart';

class ChatHistory {
  final List<ChatMessage> messages = [];

  void addMessage(ChatMessage message) {
    messages.insert(0, message);
  }

  String getFullConversation() {
    return messages
        .map((msg) => "${msg.isUser ? 'User' : 'AI'}: ${msg.text}")
        .join('\n');
  }
}
