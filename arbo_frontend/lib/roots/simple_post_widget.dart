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
        return '진행 중';
      case 'approved':
        return '승인됨';
      case 'rejected':
        return '거절됨';
      default:
        return '미정';
    }
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'pending':
        return 0.5;
      case 'approved':
        return 1.0;
      case 'rejected':
        return 0.0;
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
    specificAllPostData['status'] = 'pending';
    DateTime postTime =
        (specificAllPostData['timestamp'] as Timestamp).toDate();

    // Get the designedPicture list
    List<String> imageUrls =
        List<String>.from(specificAllPostData['designedPicture'] ?? []);

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
        // child: Container(
        //   padding: const EdgeInsets.all(8.0),
        //   color: Colors.yellow[100],
        //   child: Row(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Expanded(
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Row(
        //               children: [
        //                 Text(
        //                   specificAllPostData['nickname'],
        //                   style: const TextStyle(
        //                       fontWeight: FontWeight.bold, fontSize: 18),
        //                 ),
        //                 const SizedBox(
        //                   width: 20,
        //                 ),
        //                 Text(
        //                   specificAllPostData['topic'],
        //                   style: const TextStyle(
        //                       fontWeight: FontWeight.bold,
        //                       color: Colors.red,
        //                       fontSize: 18),
        //                 ),
        //               ],
        //             ),
        //             Text(
        //               '${postTime.year}-${postTime.month}-${postTime.day}',
        //               style: const TextStyle(color: Colors.grey),
        //             ),
        //             const SizedBox(height: 8.0),
        //             Hero(
        //               tag: 'title_${specificAllPostData['title']}',
        //               child: Text(
        //                 specificAllPostData['title'],
        //                 style: const TextStyle(
        //                     fontSize: 16, fontWeight: FontWeight.bold),
        //                 maxLines: 1,
        //                 overflow: TextOverflow.ellipsis,
        //               ),
        //             ),
        //             const SizedBox(height: 8.0),
        //             Text(
        //               '세줄요약: ${specificAllPostData['content']}',
        //               maxLines: 2,
        //               overflow: TextOverflow.ellipsis,
        //             ),
        //             const SizedBox(height: 8.0),
        //             Row(
        //               children: [
        //                 const Icon(Icons.favorite_border),
        //                 const SizedBox(width: 4.0),
        //                 Text('${specificAllPostData['hearts']}'),
        //                 const SizedBox(width: 10.0),
        //                 const Icon(Icons.comment),
        //                 const SizedBox(width: 4.0),
        //                 Text(
        //                     '${countTotalComments(specificAllPostData['comments'])}'),
        //               ],
        //             ),
        //           ],
        //         ),
        //       ),
        //       const SizedBox(width: 8.0),
        //       Container(
        //         width: 100,
        //         height: 100,
        //         color: Colors.grey,
        //         child: imageUrls.isNotEmpty
        //             ? Image.network(
        //                 imageUrls[0],
        //                 fit: BoxFit.cover,
        //                 errorBuilder: (context, error, stackTrace) {
        //                   print(error);
        //                   return Container(color: Colors.grey);
        //                 },
        //               )
        //             : Container(color: Colors.grey),
        //       ),
        //     ],
        //   ),
        // ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
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
                        Text(
                          '작성자: ${specificAllPostData['nickname']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
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
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                '세줄요약: ${specificAllPostData['content']}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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
        ));
  }
}
