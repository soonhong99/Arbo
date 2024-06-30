import 'package:arbo_frontend/data/prompt_history.dart';
import 'package:arbo_frontend/widgets/prompt_widgets/prompt_post_creation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PromptDialog extends StatefulWidget {
  final TextEditingController promptController;
  final Function(String) onSendMessage;
  final Future<void> Function() initializeChat;

  const PromptDialog({
    super.key,
    required this.promptController,
    required this.onSendMessage,
    required this.initializeChat,
  });

  @override
  _PromptDialogState createState() => _PromptDialogState();
}

class _PromptDialogState extends State<PromptDialog> {
  final ChatHistory _chatHistory = ChatHistory();
  late PostCreationHelper _postCreationHelper;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _postCreationHelper = PostCreationHelper(
      chatHistory: _chatHistory,
      onSendMessage: widget.onSendMessage,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    await widget.initializeChat();
    setState(() {
      _isLoading = false;
      _addMessage(const ChatMessage(
        text: "Hi there! I'm Chandler. How can I help you today?",
        isUser: false,
      ));
    });
  }

  void _handleSubmitted(String text) {
    widget.promptController.clear();
    _addMessage(ChatMessage(text: text, isUser: true));
    widget.onSendMessage(text).then((response) {
      _addMessage(ChatMessage(text: response, isUser: false));
    });
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _chatHistory.addMessage(message);
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _createPost() async {
    setState(() {
      _isLoading = true;
    });

    final suggestions = await _postCreationHelper.getSuggestions();

    setState(() {
      _isLoading = false;
    });

    // 여기서 게시글 작성 화면으로 네비게이트하거나 다이얼로그를 표시할 수 있습니다.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suggested Topic: ${suggestions['topic']}'),
              const SizedBox(height: 8),
              Text('Suggested Title: ${suggestions['title']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 여기서 실제 게시글 작성 화면으로 이동할 수 있습니다.
              },
              child: const Text('Create Post'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      title: const Text('Chat with Chandler'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.7,
        child: _isLoading ? _buildLoadingIndicator() : _buildChatUI(),
      ),
      actions: [
        TextButton(
          onPressed: _createPost,
          child: const Text('Create Post'),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Initializing chat..."),
        ],
      ),
    );
  }

  Widget _buildChatUI() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            controller: _scrollController,
            itemCount: _chatHistory.messages.length,
            itemBuilder: (_, int index) => _chatHistory.messages[index],
          ),
        ),
        const Divider(height: 1.0),
        Container(
          decoration: BoxDecoration(color: Theme.of(context).cardColor),
          child: _buildTextComposer(),
        ),
      ],
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: widget.promptController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Send a message',
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(widget.promptController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ChatMessage 클래스는 이전과 동일합니다.

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              child: Text(isUser ? 'You' : 'C'),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(isUser ? 'You' : 'Chandler',
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
