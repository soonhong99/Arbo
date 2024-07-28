import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/data/user_data_provider.dart';
import 'package:arbo_frontend/design/paint_stroke.dart';
import 'package:arbo_frontend/roots/simple_post_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/bot_navi_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MainWidget extends StatefulWidget {
  final VoidCallback onPreviousPage;
  final String initialCategory;

  const MainWidget({
    super.key,
    required this.onPreviousPage,
    required this.initialCategory,
  });

  @override
  State<MainWidget> createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> {
  List<String> categories = [
    'All posts',
    'Education and Development',
    'Improving Facilites',
    'Recycling Management',
    'Crime Prevention',
    'Local Commercial',
    'Local Events'
  ];
  List<String> updatedTime = [
    'Last 1 Day',
    'Last 1 Week',
    'Last 1 Month',
    'Last 1 Year',
    'All Time'
  ];
  String selectedUpdatedTime = 'Last 1 Month';

  bool showAllCategories = false;
  final UserDataProvider userDataProvider = UserDataProvider();
  late Future<void> _fetchDataFuture;
  late String selectedCategory;
  String sortBy = 'latest'; // 'latest', 'popular', 'best' 중 하나

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = userDataProvider.fetchPostData();
    selectedCategory = widget.initialCategory;
  }

  void _refreshData() {
    setState(() {
      _fetchDataFuture = userDataProvider.fetchPostData();
    });
  }

  List<DocumentSnapshot> _filteredPosts() {
    DateTime now = DateTime.now();
    DateTime cutoff;

    switch (selectedUpdatedTime) {
      case '지난 1일':
        cutoff = now.subtract(const Duration(days: 1));
        break;
      case '지난 1주':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '지난 1개월':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case '지난 1년':
        cutoff = now.subtract(const Duration(days: 365));
        break;
      default:
        cutoff = DateTime(1970);
    }

    List<DocumentSnapshot> filtered = postListSnapshot.where((post) {
      bool matchesCategory =
          selectedCategory == 'All posts' || post['topic'] == selectedCategory;
      bool matchesTime =
          (post['timestamp'] as Timestamp).toDate().isAfter(cutoff);
      return matchesCategory && matchesTime;
    }).toList();

    // 정렬
    switch (sortBy) {
      case 'latest':
        filtered.sort((a, b) => (b['timestamp'] as Timestamp)
            .compareTo(a['timestamp'] as Timestamp));
        break;
      case 'popular':
        filtered
            .sort((a, b) => (b['hearts'] as int).compareTo(a['hearts'] as int));
        break;
      case 'progress':
        // 'best' 정렬 로직을 여기에 추가하세요
        filtered.sort((a, b) {
          // 상태에 따른 우선순위 정의
          Map<String, int> statusPriority = {
            'approved': 0,
            'pending': 1,
            'rejected': 2,
          };

          int priorityA =
              statusPriority[a['status']] ?? 3; // 알 수 없는 상태는 가장 낮은 우선순위
          int priorityB = statusPriority[b['status']] ?? 3;

          // 우선 상태로 정렬
          int comparison = priorityA.compareTo(priorityB);

          // 상태가 같을 경우, 시간순으로 정렬 (최신이 위로)
          if (comparison == 0) {
            return (b['timestamp'] as Timestamp)
                .compareTo(a['timestamp'] as Timestamp);
          }

          return comparison;
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.1;

    return Scaffold(
      body: Stack(children: [
        CustomPaint(
          painter: StrokePainter(userPaintBackGround),
          size: Size.infinite,
        ),
        SafeArea(
          child: FutureBuilder(
            future: _fetchDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('오류가 발생했습니다: ${snapshot.error}'),
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          DropdownButton<String>(
                            value: selectedCategory,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCategory = newValue!;
                              });
                            },
                            items: categories
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: selectedUpdatedTime,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedUpdatedTime = newValue!;
                              });
                            },
                            items: updatedTime
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      sortBy = 'latest';
                                    });
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.noise_aware_sharp),
                                      Text('Newest'),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      sortBy = 'popular';
                                    });
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.fire_hydrant_alt_sharp),
                                      Text('Hottest'),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      sortBy = 'progress';
                                    });
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.local_fire_department_sharp),
                                      Text('progress'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildPostList(screenWidth, horizontalPadding),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ]),
      bottomNavigationBar: BotNaviWidget(
        postData: null,
        refreshDataCallback: () {
          _refreshData();
        },
        onPreviousPage: widget.onPreviousPage,
      ),
    );
  }

  ListView _buildPostList(double screenWidth, double horizontalPadding) {
    List<DocumentSnapshot> filteredPosts = _filteredPosts();
    return ListView.separated(
      scrollDirection: Axis.vertical,
      separatorBuilder: (context, index) => const SizedBox(
        height: 10,
      ),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        var post = filteredPosts[index];

        userDataProvider.makeAllDataLocal(post);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              SimplePostWidget(
                postId: post.id,
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        );
      },
    );
  }
}
