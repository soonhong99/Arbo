import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/roots/root_screen.dart';
import 'package:arbo_frontend/widgets/main_widgets/loading_screen.dart';
import 'package:arbo_frontend/widgets/search_widgets/search_design_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomSliverAppBar extends StatefulWidget {
  final User? user;
  final String? nickname;
  final VoidCallback? onLogout;
  final VoidCallback? onLogin;
  final VoidCallback? onUserInfo;

  const CustomSliverAppBar({
    super.key,
    this.user,
    this.nickname,
    this.onLogout,
    this.onLogin,
    this.onUserInfo,
  });

  @override
  State<CustomSliverAppBar> createState() => _CustomSliverAppBarState();
}

class _CustomSliverAppBarState extends State<CustomSliverAppBar> {
  int _alertCount = 0;
  final Map<String, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _fetchAlertCount();
    }
  }

  Future<void> _deleteAlerts(String postId) async {
    final userDoc =
        firestore_instance.collection('users').doc(widget.user!.uid);

    await userDoc.update({
      'alertMap.alertHeart': FieldValue.arrayRemove((await userDoc.get())
              .data()?['alertMap']['alertHeart']
              .where((alert) => alert['postId'] == postId)
              .toList() ??
          []),
      'alertMap.alertComment': FieldValue.arrayRemove((await userDoc.get())
              .data()?['alertMap']['alertComment']
              .where((alert) => alert['postId'] == postId)
              .toList() ??
          []),
    });

    // 알림 개수 업데이트
    await _fetchAlertCount();
  }

  Future<void> _fetchAlertCount() async {
    final userDoc = await firestore_instance
        .collection('users')
        .doc(widget.user!.uid)
        .get();
    final alertMap = userDoc.data()?['alertMap'] ?? {};
    final alertCommentCount = (alertMap['alertComment'] as List?)?.length ?? 0;
    final alertHeartCount = (alertMap['alertHeart'] as List?)?.length ?? 0;
    setState(() {
      _alertCount = alertCommentCount + alertHeartCount;
    });
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: firestore_instance
                .collection('users')
                .doc(widget.user!.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Text('No data available');
              }

              final userData = snapshot.data!.data();
              if (userData == null) {
                return const Text('User data is null');
              }

              final alertMap =
                  userData['alertMap'] as Map<String, dynamic>? ?? {};
              final alertComments = alertMap['alertComment'] as List? ?? [];
              final alertHearts = alertMap['alertHeart'] as List? ?? [];

              // 여기서부터 알림 처리 로직...
              Map<String, List<dynamic>> groupedAlerts = {};
              for (var comment in alertComments) {
                String postId = comment['postId'] as String? ?? '';
                groupedAlerts.putIfAbsent(postId, () => []).add(comment);
              }
              for (var heart in alertHearts) {
                String postId = heart['postId'] as String? ?? '';
                groupedAlerts.putIfAbsent(postId, () => []).add(heart);
              }

              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: groupedAlerts.entries.map((entry) {
                        String postId = entry.key;
                        List<dynamic> alerts = entry.value;
                        String postTitle = (alerts.first['title'] as String?) ??
                            'Unknown Title';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text('$postTitle에 대한 알림이 왔습니다!'),
                              trailing: IconButton(
                                icon: Icon(_expandedStates[postId] ?? false
                                    ? Icons.arrow_drop_down
                                    : Icons.arrow_right),
                                onPressed: () {
                                  setState(() {
                                    _expandedStates[postId] =
                                        !(_expandedStates[postId] ?? false);
                                  });
                                },
                              ),
                            ),
                            if (_expandedStates[postId] ?? false)
                              ...alerts
                                  .where((alert) =>
                                      alert['userId'] != widget.user!.uid)
                                  .map((alert) => ListTile(
                                        title: Text(alert['comment'] != null
                                            ? '${alert['nickname'] ?? 'Unknown'}님이 댓글을 달았습니다: ${alert['comment']}'
                                            : '${alert['nickname'] ?? 'Unknown'}님이 좋아요를 눌렀습니다'),
                                        subtitle: Text(DateTime.parse(
                                                alert['commentTimestamp'] ??
                                                    alert['heartTimestamp'] ??
                                                    DateTime.now()
                                                        .toIso8601String())
                                            .toLocal()
                                            .toString()),
                                      )),
                            ElevatedButton(
                              child: const Text('해당 게시글로 이동하기!'),
                              onPressed: () async {
                                // 알림 삭제 로직
                                await _deleteAlerts(postId);
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LoadingScreen(postId: postId),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return SliverAppBar(
      floating: true,
      snap: true,
      foregroundColor: Colors.green,
      automaticallyImplyLeading: false,
      actions: [
        if (widget.user != null)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _showAlertDialog,
              ),
              if (_alertCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_alertCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
      ],
      title: Row(
        children: [
          TextButton(
            onPressed: () {
              selectedIndex = -1;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const RootScreen(),
                ),
              );
            },
            child: const Text('CommPain\'t'),
          ),
          const SizedBox(
            width: 60,
          ),
          SearchDesignBar(
            screenWidth: screenWidth / 2,
          ),
          const Spacer(),
          if (widget.user != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                '${widget.nickname}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
            ),
          ],
          TextButton(
            onPressed: () {
              widget.user == null
                  ? widget.onLogin?.call()
                  : widget.onUserInfo?.call();
            },
            child: Row(
              children: [
                Icon(widget.user == null ? Icons.login : Icons.person),
                Text(widget.user == null ? '로그인' : '마이페이지'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
