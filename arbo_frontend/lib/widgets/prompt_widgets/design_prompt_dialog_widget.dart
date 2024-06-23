import 'package:flutter/material.dart';

class DesignPromptDialog extends StatefulWidget {
  final TextEditingController promptController;
  final List<dynamic> searchHistory;
  final Function(dynamic) onSearch;

  const DesignPromptDialog({
    super.key,
    required this.promptController,
    required this.searchHistory,
    required this.onSearch,
  });

  @override
  _DesignPromptDialogState createState() => _DesignPromptDialogState();
}

class _DesignPromptDialogState extends State<DesignPromptDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      title: const Text('디자인 프롬프트'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Hero(
              tag: 'designPrompt',
              child: TextField(
                  controller: widget.promptController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '디자인 프롬프트 입력',
                  ),
                  onSubmitted: (value) {
                    widget.onSearch(value);
                    Navigator.pop(context);
                  }),
            ),
            if (widget.searchHistory.isNotEmpty) ...[
              const Text(
                '최근 검색 기록',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.searchHistory
                    .map((history) => GestureDetector(
                          onTap: () {
                            widget.promptController.text = history;
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(history),
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              '프롬프트 사용 주의사항',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '1. 주의사항 내용 1\n'
              '2. 주의사항 내용 2\n'
              '3. 주의사항 내용 3',
            ),
            const SizedBox(height: 20),
            const Text(
              '프롬프트 검색 예시',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '예시 1: 예시 내용 1\n'
              '예시 2: 예시 내용 2\n'
              '예시 3: 예시 내용 3',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('취소'),
        ),
      ],
    );
  }
}
