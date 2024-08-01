import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentWidget extends StatelessWidget {
  final Map<String, dynamic> comment;
  final VoidCallback onHeartPressed;
  final String? currentUserId;
  final Function(String) onReplyPressed;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.onHeartPressed,
    this.currentUserId,
    required this.onReplyPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasLiked = comment['likedBy']?.contains(currentUserId) ?? false;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(comment['nickname'][0].toUpperCase()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['nickname'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatTimestamp(comment['timestamp'] as Timestamp),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    hasLiked ? Icons.favorite : Icons.favorite_border,
                    color: hasLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: onHeartPressed,
                ),
                Text(
                  '${comment['hearts'] ?? 0}',
                  style: const TextStyle(color: Colors.grey),
                ),
                IconButton(
                  icon: const Icon(Icons.reply),
                  onPressed: () => onReplyPressed(comment['commentId']),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment['comment']),
            if (comment['replies'] != null && comment['replies'].isNotEmpty)
              ExpansionTile(
                title: Text('${comment['replies'].length} Replies'),
                children: (comment['replies'] as List)
                    .map((reply) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Text(reply['nickname'][0].toUpperCase()),
                          ),
                          title: Text(reply['nickname']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reply['comment']),
                              Text(
                                _formatTimestamp(
                                    reply['timestamp'] as Timestamp),
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(Timestamp timestamp) {
  final now = DateTime.now();
  final date = timestamp.toDate();
  final difference = now.difference(date);

  if (difference.inDays > 7) {
    return DateFormat('yyyy-MM-dd').format(date);
  } else if (difference.inDays > 0) {
    return '${difference.inDays} days ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hours ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} minutes ago';
  } else {
    return 'Just before';
  }
}
