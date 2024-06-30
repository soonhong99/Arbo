import 'package:arbo_frontend/widgets/prompt_widgets/prompt_dialog_widget.dart';

class ChatHistory {
  final List<ChatMessage> messages = [];

  void addMessage(ChatMessage message) {
    messages.add(message);
  }

  String getFullConversation() {
    return messages
        .map((msg) => "${msg.isUser ? 'User' : 'AI'}: ${msg.text}")
        .join('\n');
  }
}
