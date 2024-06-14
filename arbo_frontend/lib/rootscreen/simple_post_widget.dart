import 'package:arbo_frontend/resources/history_data.dart';
import 'package:arbo_frontend/resources/user_data.dart';
import 'package:arbo_frontend/screens/specific_post_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SimplePostWidget extends StatefulWidget {
  final String postId;

  const SimplePostWidget({
    super.key,
    required this.postId,
  });

  @override
  State<SimplePostWidget> createState() => _SimplePostWidgetState();
}

class _SimplePostWidgetState extends State<SimplePostWidget> {
  Map<String, dynamic> specificAllPostData = {};

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    specificAllPostData = allPostDataWithPostId[widget.postId] ?? {};
    specificAllPostData['comments'] = specificAllPostData['comments'] ?? [];
    DateTime postTime =
        (specificAllPostData['timestamp'] as Timestamp).toDate();
    return GestureDetector(
      onTap: () async {
        // 방문기록 추가
        page_location++;
        addPageToHistory(specificAllPostData);

        // Navigate to SpecificPostScreen and wait for the result
        final result = await Navigator.pushNamed(
          context,
          SpecificPostScreen.routeName,
          arguments: specificAllPostData,
        );

        // Update the local state if result is returned
        if (result != null && result is Map<String, dynamic>) {
          setState(() {
            specificAllPostData = result;
          });
        }
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
                        specificAllPostData['nickname'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Text(
                        specificAllPostData['topic'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 18),
                      ),
                    ],
                  ),
                  Text(
                    '${postTime.year}-${postTime.month}-${postTime.day}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8.0),
                  Hero(
                    tag: 'title_${specificAllPostData['title']}',
                    child: Text(
                      specificAllPostData['title'],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '세줄요약: ${specificAllPostData['content']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border),
                      const SizedBox(width: 4.0),
                      Text('${specificAllPostData['hearts']}'),
                      const SizedBox(width: 10.0),
                      const Icon(Icons.comment),
                      const SizedBox(width: 4.0),
                      Text('${specificAllPostData['comments'].length}'),
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
