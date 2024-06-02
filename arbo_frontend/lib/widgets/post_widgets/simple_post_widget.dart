import 'package:arbo_frontend/resources/fetch_data.dart';
import 'package:arbo_frontend/resources/history_data.dart';
import 'package:arbo_frontend/resources/specific_data.dart';
import 'package:arbo_frontend/resources/user_data.dart';
import 'package:arbo_frontend/screens/specific_post_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SimplePostWidget extends StatefulWidget {
  final String postId;
  final String postTopic;
  final String nickname;
  final String title;
  final String content;
  final String userId;
  final int hearts;
  final DateTime timestamp;

  const SimplePostWidget({
    super.key,
    required this.nickname,
    required this.title,
    required this.content,
    required this.hearts,
    required this.timestamp,
    required this.postTopic,
    required this.postId,
    required this.userId,
  });

  @override
  State<SimplePostWidget> createState() => _SimplePostWidgetState();
}

class _SimplePostWidgetState extends State<SimplePostWidget> {
  final FetchData fetchData = FetchData();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData.fetchPostAndCommentsData(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SpecificData.updateData(
          postId: widget.postId,
          postTopic: widget.postTopic,
          nickname: widget.nickname,
          title: widget.title,
          content: widget.content,
          hearts: widget.hearts,
          comments: commentstoMap,
          timestamp: widget.timestamp,
          userId: widget.userId,
        );
        Navigator.pushNamed(context, SpecificPostScreen.routeName,
            arguments: SpecificData.specificData);
        // 방문기록 추가
        page_location++;
        addPageToHistory(SpecificData.specificData);
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.yellow[100],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.nickname,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Text(
                        widget.postTopic,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 18),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.timestamp.year}-${widget.timestamp.month}-${widget.timestamp.day}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8.0),
                  Hero(
                    tag: 'title_${widget.title}',
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '세줄요약: ${widget.content}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border),
                      const SizedBox(width: 4.0),
                      Text('${widget.hearts}'),
                      const SizedBox(width: 10.0),
                      const Icon(Icons.comment),
                      const SizedBox(width: 4.0),
                      Text('${commentsSnapshotDocs.length}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              width:
                  100, // Adjust the width of the thumbnail container as needed
              height: 100,
              color: Colors.grey, // Placeholder color for thumbnail
              // Add your thumbnail widget or image here
            ),
          ],
        ),
      ),
    );
  }
}
