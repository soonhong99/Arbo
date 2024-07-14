import 'package:algolia/algolia.dart';
import 'package:arbo_frontend/data/prompt_history.dart';
import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/extractNoun/responseServer.dart';
import 'package:arbo_frontend/widgets/main_widgets/loading_screen.dart';
import 'package:arbo_frontend/widgets/prompt_widgets/chat_message.dart';
import 'package:arbo_frontend/widgets/prompt_widgets/prompt_post_creation.dart';
import 'package:arbo_frontend/widgets/search_widgets/search_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:arbo_frontend/screens/create_post_screen.dart';

class AlgoliaService {
  static Algolia algolia = Algolia.init(
    applicationId: dotenv.env['ALGOLIA_APPLICATION_ID']!,
    apiKey: dotenv.env['ALGOLIA_API_KEY']!,
  );
}

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
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isLoading = true;
  bool createPost = false;
  TextSelection? _lastSelection;
  late final FocusNode _focusNode;
  late PostCreationHelper _postCreationHelper;
  late TextEditingController textInPrompt;

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
    _focusNode = FocusNode(
      onKey: (FocusNode node, RawKeyEvent evt) {
        if (evt is RawKeyDownEvent) {
          if (evt.isShiftPressed &&
              evt.logicalKey == LogicalKeyboardKey.enter) {
            _insertNewLine();
            return KeyEventResult.handled;
          } else if (!evt.isShiftPressed &&
              evt.logicalKey == LogicalKeyboardKey.enter) {
            _handleSubmitted(widget.promptController.text);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _insertNewLine() {
    final text = widget.promptController.text;
    final selection = widget.promptController.selection;
    final newText = text.replaceRange(selection.start, selection.end, '\n');
    widget.promptController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + 1),
    );
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

  void _clearAndStopListening() {
    _stopListening();
    widget.promptController.clear();
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

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isNotEmpty) {
      widget.promptController.clear();

      // if (_isListening == true) {
      //   _focusNode.unfocus();
      //   _stopListening();
      // } else {
      //   _focusNode.requestFocus();
      // }

      _addMessage(ChatMessage(text: text, isUser: true));

      try {
        String response = await widget.onSendMessage(text);
        _addMessage(ChatMessage(text: response, isUser: false));
      } catch (e) {
        print('Error getting response: $e');
        _addMessage(const ChatMessage(
            text: "Sorry, an error occurred.", isUser: false));
      }
    }
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

  void _searchSimilarBoards(Map<String, String> suggestions) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("키워드를 추출하는 중..."),
            ],
          ),
        );
      },
    );

    List<String> nounQuery =
        await extractNounsWithPython(suggestions['title'] ?? '');

    Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

    if (nounQuery.isEmpty) {
      _showNoKeywordsDialog(suggestions);
    } else {
      _showKeywordsDialog(nounQuery, suggestions);
    }
  }

  void _showKeywordsDialog(
      List<String> keywords, Map<String, String> suggestions) {
    List<String> selectedKeywords = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('추출된 키워드'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('검색에 사용할 키워드를 선택해주세요. (중복 선택 가능)'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: keywords
                      .map((keyword) => ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  selectedKeywords.contains(keyword)
                                      ? Colors.blue
                                      : null,
                            ),
                            onPressed: () {
                              setState(() {
                                if (selectedKeywords.contains(keyword)) {
                                  selectedKeywords.remove(keyword);
                                } else {
                                  selectedKeywords.add(keyword);
                                }
                              });
                            },
                            child: Text(keyword),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                Text('선택된 키워드: ${selectedKeywords.join(", ")}'),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                onPressed: selectedKeywords.isNotEmpty
                    ? () {
                        Navigator.of(context).pop();
                        _searchWithKeywords(selectedKeywords, suggestions);
                      }
                    : null,
                child: const Text('검색하기'),
              ),
            ],
          );
        });
      },
    );
  }

  void _searchWithKeywords(
      List<String> keywords, Map<String, String> suggestions) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("유사한 게시물을 검색 중..."),
            ],
          ),
        );
      },
    );

    final results = await _searchSimilarBoardsAlgolia(keywords.join(" "));

    Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

    if (results.isEmpty) {
      _showNoSimilarBoardsDialog(suggestions);
    } else {
      _showSimilarBoardsDialog(results, suggestions);
    }
  }

  Future<List<AlgoliaObjectSnapshot>> _searchSimilarBoardsAlgolia(
      String query) async {
    try {
      AlgoliaQuery algoliaQuery = AlgoliaService.algolia.instance
          .index(dotenv.env['ALGOLIA_INDEX_NAME']!);
      algoliaQuery = algoliaQuery.query(query);
      algoliaQuery = algoliaQuery.setHitsPerPage(3);

      AlgoliaQuerySnapshot querySnap = await algoliaQuery.getObjects();
      return querySnap.hits;
    } catch (e) {
      print('Algolia search error: $e');
      return [];
    }
  }

  void _showNoSimilarBoardsDialog(Map<String, String> suggestions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Similar Boards'),
          content: const Text('아이쿠! 해당 내용으로된 게시물이 없네요!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 여기에 새 게시물 작성 로직 추가
                _createNewPost(suggestions);
              },
              child: const Text('새로운 게시물 만들기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  void _showNoKeywordsDialog(Map<String, String> suggestions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('키워드 없음'),
          content: const Text('추출된 키워드가 없습니다. 새로운 게시물을 작성하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createNewPost(suggestions);
              },
              child: const Text('새로운 게시물 만들기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  void _showSimilarBoardsDialog(
      List<AlgoliaObjectSnapshot> results, Map<String, String> suggestions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Similar Boards To JOIN!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...results.map((result) => ListTile(
                    title: Text(result.data['title'] ?? 'Untitled'),
                    subtitle:
                        Text(result.data['reason'] ?? 'No reason provided'),
                    onTap: () => _joinBoard(result.objectID),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createNewPost(suggestions);
              },
              child: const Text('새로운 게시물 만들기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  void _joinBoard(String boardId) async {
    Navigator.of(context).pop();

    try {
      DocumentReference userRef =
          firestore_instance.collection('users').doc(userUid);
      DocumentReference postRef =
          firestore_instance.collection('posts').doc(boardId);

      if (firstSpecificPostTouch) {
        likedPosts = loginUserData!['하트 누른 게시물'] ?? [];
        firstSpecificPostTouch = false;
      }

      // 사용자가 이미 하트를 눌렀는지 확인
      bool hasLiked = likedPosts.contains(boardId);

      if (hasLiked) {
        // 이미 하트를 누른 경우
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('이미 참여 중'),
              content: const Text('해당 게시물에 이미 하트를 누르셨네요!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      } else {
        // 하트를 누르지 않은 경우, 하트를 누르고 참여 처리
        await userRef.update({
          '하트 누른 게시물': FieldValue.arrayUnion([boardId])
        });
        await postRef.update({'hearts': FieldValue.increment(1)});

        setState(() {
          likedPosts.add(boardId);
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('참여 완료'),
              content: const Text('해당 게시물에 하트를 누르고, 참여가 완료되었습니다!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 프롬프트 창도 끄기
                    Navigator.of(context).pop();
                    // 여기에 게시물 상세 페이지로 이동하는 로직을 추가할 수 있습니다.
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SearchDetailScreen(postId: boardId),
                    ));
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error joining board: $e');
      // 에러 처리 로직 추가
    }
  }

  void _createNewPost(Map<String, String> suggestions) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String postId = await createNewPost(
          suggestions['title'] ?? 'Untitled',
          suggestions['reason'] ?? 'No content',
          suggestions['topic'] ?? 'Uncategorized');

      setState(() {
        _isLoading = false;
      });

      // 성공 메시지 표시
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('New post created successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // PromptDialog도 닫기

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LoadingScreen(postId: postId),
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // 에러 메시지 표시
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create post: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _navigateToBoard(String boardId) {
    // 여기에 선택한 게시판으로 이동하는 로직을 구현합니다.
    print('Navigating to board: $boardId');
    Navigator.of(context).pop(); // 다이얼로그 닫기
    // 예: Navigator.of(context).push(MaterialPageRoute(builder: (_) => BoardScreen(boardId: boardId)));
  }

  void _createPost() async {
    setState(() {
      createPost = true;
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
                _searchSimilarBoards(suggestions);
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
    return WillPopScope(
      onWillPop: () async => false, // 뒤로 가기 버튼 비활성화
      child: AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Chat with Social community'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.7,
          child:
              _isLoading ? _buildLoadingIndicator(createPost) : _buildChatUI(),
        ),
        actions: [
          TextButton(
            onPressed: _createPost,
            child: const Text('Create Post With Dialog!'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(bool createPost) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          if (createPost)
            const Text("MinJi makes Post..")
          else
            const Text("Initializing chat..."),
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            IconButton(
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              onPressed: () {
                _listen();
              },
              color: _isListening ? Colors.red : null,
            ),
            Flexible(
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                child: TextField(
                  controller: widget.promptController,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChanged: _handleTextChange,
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening...' : 'Send a message',
                    hintMaxLines: 1,
                    helperText: 'Shift+Enter로 줄 바꿈, Enter로 메시지 전송',
                    helperStyle: const TextStyle(fontSize: 12),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = widget.promptController.text;
                    _clearAndStopListening();

                    _handleSubmitted(text);
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTextChange(String text) {
    final currentSelection = widget.promptController.selection;
    final previousText =
        _lastSelection != null ? widget.promptController.text : '';

    if (currentSelection.baseOffset == currentSelection.extentOffset &&
        currentSelection.baseOffset < previousText.length &&
        text.length < previousText.length) {
      // Backspace가 눌렸을 가능성이 있음
      final deletedChar = previousText[currentSelection.baseOffset];
      if (deletedChar == '\n') {
        // 줄바꿈이 삭제되었다면, 현재 줄을 이전 줄의 끝으로 이동
        _mergeLines(currentSelection.baseOffset);
      }
    } else {
      // 일반적인 텍스트 변경 처리
      setState(() {
        // 텍스트가 너무 길어지면 자동으로 줄 바꿈
        if (text.length > 80 && !text.contains('\n')) {
          widget.promptController.text =
              '${text.substring(0, 80)}\n${text.substring(80)}';
          widget.promptController.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.promptController.text.length),
          );
        }
      });
    }

    _lastSelection = currentSelection;
  }

  void _mergeLines(int cursorPosition) {
    final text = widget.promptController.text;
    final beforeCursor = text.substring(0, cursorPosition);
    final afterCursor = text.substring(cursorPosition);

    final lastNewlineIndex = beforeCursor.lastIndexOf('\n');
    if (lastNewlineIndex == -1) return; // 이전 줄이 없으면 아무 것도 하지 않음

    final previousLine = beforeCursor.substring(0, lastNewlineIndex);
    final currentLine = beforeCursor.substring(lastNewlineIndex + 1);

    final newText = '$previousLine$currentLine$afterCursor';
    final newCursorPosition = previousLine.length + currentLine.length;

    widget.promptController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }
}
