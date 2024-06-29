// import 'package:flutter/material.dart';

// class DesignPromptDialog extends StatefulWidget {
//   final TextEditingController promptController;
//   final List<dynamic> searchHistory;
//   final Function(dynamic) onSearch;

//   const DesignPromptDialog({
//     super.key,
//     required this.promptController,
//     required this.searchHistory,
//     required this.onSearch,
//   });

//   @override
//   _DesignPromptDialogState createState() => _DesignPromptDialogState();
// }

// class _DesignPromptDialogState extends State<DesignPromptDialog> {
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       contentPadding: const EdgeInsets.all(16.0),
//       title: const Text('디자인 프롬프트'),
//       content: SizedBox(
//         width: MediaQuery.of(context).size.width * 0.7,
//         height: MediaQuery.of(context).size.height * 0.7,
//         child: Column(
//           children: [
//             Hero(
//               tag: 'designPrompt',
//               child: TextField(
//                   controller: widget.promptController,
//                   decoration: const InputDecoration(
//                     border: OutlineInputBorder(),
//                     labelText: '디자인 프롬프트 입력',
//                   ),
//                   onSubmitted: (value) {
//                     widget.onSearch(value);
//                     Navigator.pop(context);
//                   }),
//             ),
//             if (widget.searchHistory.isNotEmpty) ...[
//               const Text(
//                 '최근 검색 기록',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: widget.searchHistory
//                     .map((history) => GestureDetector(
//                           onTap: () {
//                             widget.promptController.text = history;
//                           },
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Text(history),
//                           ),
//                         ))
//                     .toList(),
//               ),
//             ],
//             const SizedBox(height: 20),
//             const Text(
//               '프롬프트 사용 주의사항',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               '1. 주의사항 내용 1\n'
//               '2. 주의사항 내용 2\n'
//               '3. 주의사항 내용 3',
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               '프롬프트 검색 예시',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               '예시 1: 예시 내용 1\n'
//               '예시 2: 예시 내용 2\n'
//               '예시 3: 예시 내용 3',
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           child: const Text('취소'),
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class DesignPromptDialog extends StatefulWidget {
  final TextEditingController promptController;
  final Function(String) onSendMessage;
  final Future<void> Function() initializeChat;

  const DesignPromptDialog({
    super.key,
    required this.promptController,
    required this.onSendMessage,
    required this.initializeChat,
  });

  @override
  _DesignPromptDialogState createState() => _DesignPromptDialogState();
}

class _DesignPromptDialogState extends State<DesignPromptDialog> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
      _messages.insert(0, message);
    });

    // 프레임이 끝난 후 스크롤 동작 수행
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
            itemCount: _messages.length,
            itemBuilder: (_, int index) => _messages[index],
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
