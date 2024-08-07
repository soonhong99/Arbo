import 'package:arbo_frontend/data/history_data.dart';
import 'package:arbo_frontend/data/user_data.dart';
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

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'In Progress';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'clear':
        return 'Paint Done!';
      default:
        return 'None';
    }
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'pending':
        return 0.5;
      case 'approved':
        return 1.0;
      case 'rejected':
        return 1.0;
      case 'clear':
        return 1.0;
      default:
        return 0.0;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'clear':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

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
        } else if (result == {}) {
          return;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: specificAllPostData['status'] == 'clear'
                  ? Colors.blue.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
              spreadRadius: specificAllPostData['status'] == 'clear' ? 3 : 2,
              blurRadius: specificAllPostData['status'] == 'clear' ? 7 : 5,
              offset: const Offset(0, 3),
            ),
          ],
          border: specificAllPostData['status'] == 'clear'
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specificAllPostData['title'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              'Pain\'ter:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              specificAllPostData['nickname'],
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${specificAllPostData['country']}/${specificAllPostData['city']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(specificAllPostData['status']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(specificAllPostData['status']),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _getProgressValue(specificAllPostData['status']),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatusColor(specificAllPostData['status'])),
            ),
            if (specificAllPostData['status'] == 'clear' &&
                (specificAllPostData['answeringPosts'] ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.question_answer,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'This post has ${specificAllPostData['answeringPosts']} answering posts!',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.article, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Post Content:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specificAllPostData['content'],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('${specificAllPostData['hearts']}'),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.comment, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                        '${countTotalComments(specificAllPostData['comments'])}'),
                  ],
                ),
                Text(
                  '${postTime.year}-${postTime.month}-${postTime.day}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
