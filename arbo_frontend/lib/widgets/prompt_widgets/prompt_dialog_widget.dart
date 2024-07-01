import 'package:arbo_frontend/data/prompt_history.dart';
import 'package:arbo_frontend/widgets/prompt_widgets/prompt_post_creation.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class PromptDialog extends StatefulWidget {
  final TextEditingController promptController;
  final Function(String) onSendMessage;
  final Future<void> Function() initializeChat;
  final GenerativeModel vertexAIModel;

  const PromptDialog({
    super.key,
    required this.promptController,
    required this.onSendMessage,
    required this.initializeChat,
    required this.vertexAIModel,
  });

  @override
  _PromptDialogState createState() => _PromptDialogState();
}

class _PromptDialogState extends State<PromptDialog> {
  final ChatHistory _chatHistory = ChatHistory();
  late PostCreationHelper _postCreationHelper;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech.initialize();
    _postCreationHelper = PostCreationHelper(
      chatHistory: _chatHistory,
      vertexAIModel: widget.vertexAIModel,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) => print('onError: $errorNotification'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              widget.promptController.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      _stopListening();
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _initializeChat() async {
    await widget.initializeChat();
    setState(() {
      _isLoading = false;
      _addMessage(const ChatMessage(
        text: "Hello my friend! What happened today?",
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
    _stopListening(); // 메시지를 보낼 때 마이크 끄기
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
              const SizedBox(height: 8),
              Text('Suggested reason: ${suggestions['reason']}'),
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
      title: const Text('Chat with Social community'),
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
        if (_isListening)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Listening...",
                style: TextStyle(fontStyle: FontStyle.italic)),
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
            IconButton(
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              onPressed: _listen,
              color: _isListening ? Colors.red : null,
            ),
            Flexible(
              child: TextField(
                controller: widget.promptController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(
                  hintText: _isListening ? 'Listening...' : 'Send a message',
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

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isUser) ...[
            const CircleAvatar(child: Text('C')),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Text(isUser ? 'You' : 'MinJi',
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(text),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8.0),
            const CircleAvatar(child: Text('You')),
          ],
        ],
      ),
    );
  }
}
