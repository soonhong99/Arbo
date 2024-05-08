import 'package:flutter/material.dart';

class HumorPostWidget extends StatefulWidget {
  final String nickname;
  final String thumbnailUrl;
  final String title;
  final String content;
  final int likes;
  final int comments;
  final DateTime timestamp;

  const HumorPostWidget({
    super.key,
    required this.nickname,
    required this.thumbnailUrl,
    required this.title,
    required this.content,
    required this.likes,
    required this.comments,
    required this.timestamp,
  });

  @override
  _HumorPostWidgetState createState() => _HumorPostWidgetState();
}

class _HumorPostWidgetState extends State<HumorPostWidget> {
  bool _showFullContent = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.yellow[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.nickname,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.timestamp.year}-${widget.timestamp.month}-${widget.timestamp.day}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          SizedBox(
            height: 100,
            child: Image.network(
              widget.thumbnailUrl,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8.0),
          _buildContent(),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_border),
                  const SizedBox(width: 4.0),
                  Text('${widget.likes}'),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.comment),
                  const SizedBox(width: 4.0),
                  Text('${widget.comments}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _showFullContent
              ? widget.content
              : '${widget.content.substring(0, 50)}...',
          maxLines: _showFullContent ? null : 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (!_showFullContent)
          TextButton(
            onPressed: () {
              setState(() {
                _showFullContent = true;
              });
            },
            child: const Text('...더보기'),
          ),
      ],
    );
  }
}
