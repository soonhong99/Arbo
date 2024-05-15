import 'package:arbo_frontend/resources/previous_specific_data.dart';
import 'package:arbo_frontend/screens/specific_post_screen.dart';
import 'package:flutter/material.dart';

class SimplePostWidget extends StatelessWidget {
  final String postTopic;
  final String nickname;
  final String title;
  final String content;
  final int likes;
  final int comments;
  final DateTime timestamp;

  const SimplePostWidget({
    super.key,
    required this.nickname,
    required this.title,
    required this.content,
    required this.likes,
    required this.comments,
    required this.timestamp,
    required this.postTopic,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        PreviousSpecificData.updateData(
            postTopic: postTopic,
            nickname: nickname,
            title: title,
            content: content,
            likes: likes,
            comments: comments,
            timestamp: timestamp);
        Navigator.pushNamed(context, SpecificPostScreen.routeName,
            arguments: PreviousSpecificData.previousSpecific);
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
                      Hero(
                        tag: 'nickname_$nickname',
                        child: Text(
                          nickname,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Hero(
                        tag: 'postTopic_$postTopic',
                        child: Text(
                          postTopic,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${timestamp.year}-${timestamp.month}-${timestamp.day}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8.0),
                  Hero(
                    tag: 'title_$title',
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '세줄요약: $content',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border),
                      const SizedBox(width: 4.0),
                      Text('$likes'),
                      const SizedBox(width: 10.0),
                      const Icon(Icons.comment),
                      const SizedBox(width: 4.0),
                      Text('$comments'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Hero(
              tag: 'thumbnail_$title',
              child: Container(
                width:
                    100, // Adjust the width of the thumbnail container as needed
                height: 100,
                color: Colors.grey, // Placeholder color for thumbnail
                // Add your thumbnail widget or image here
              ),
            ),
          ],
        ),
      ),
    );
  }
}
