import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/data/user_data_provider.dart';
import 'package:arbo_frontend/design/paint_stroke.dart';
import 'package:arbo_frontend/roots/simple_post_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/bot_navi_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainWidget extends StatefulWidget {
  const MainWidget({
    super.key,
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
  int currentPage = 1;
  int postsPerPage = 5;
  int pageGroupSize = 10;
  final ScrollController _scrollController = ScrollController();
  bool showPaginationButtons = false;

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = userDataProvider.fetchPostData();
    // selectedCategory = widget.initialCategory;
    selectedCategory = selectedCategoryinRoot;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() {
        showPaginationButtons = true;
      });
    } else {
      setState(() {
        showPaginationButtons = false;
      });
    }
  }

  void _changeSortBy(String newSortBy) {
    setState(() {
      sortBy = newSortBy;
      currentPage = 1; // 페이지를 1로 리셋
    });
    _scrollToTop(); // 리스트를 맨 위로 스크롤
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
      case 'Last 1 Day':
        cutoff = now.subtract(const Duration(days: 1));
        break;
      case 'Last 1 Week':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 'Last 1 Month':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case 'Last 1 Year':
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
          painter: PathPainter(userPaintBackGround),
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
                                  onPressed: () => _changeSortBy('latest'),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.noise_aware_sharp),
                                      Text('Newest'),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _changeSortBy('popular'),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.fire_hydrant_alt_sharp),
                                      Text('Hottest'),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _changeSortBy('progress'),
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
                    if (showPaginationButtons) _buildPaginationButtons(),
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
      ),
    );
  }

  Widget _buildPostList(double screenWidth, double horizontalPadding) {
    List<DocumentSnapshot> filteredPosts = _filteredPosts();
    int startIndex = (currentPage - 1) * postsPerPage;
    int endIndex = startIndex + postsPerPage;
    if (endIndex > filteredPosts.length) {
      endIndex = filteredPosts.length;
    }
    List<DocumentSnapshot> currentPagePosts =
        filteredPosts.sublist(startIndex, endIndex);

    return ListView.separated(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: currentPagePosts.length + 1,
      itemBuilder: (context, index) {
        if (index == currentPagePosts.length) {
          // 마지막 아이템 다음에 추가 공간
          return const SizedBox(height: 60); // 페이지 버튼과의 간격
        }
        var post = currentPagePosts[index];
        userDataProvider.makeAllDataLocal(post);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SimplePostWidget(postId: post.id),
        );
      },
    );
  }

  Widget _buildPaginationButtons() {
    List<DocumentSnapshot> filteredPosts = _filteredPosts();
    int totalPages = (filteredPosts.length / postsPerPage).ceil();
    int currentGroup = (currentPage - 1) ~/ pageGroupSize;
    int startPage = currentGroup * pageGroupSize + 1;
    int endPage = (startPage + pageGroupSize - 1) > totalPages
        ? totalPages
        : (startPage + pageGroupSize - 1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (startPage > 1)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  currentPage = startPage - 1;
                  _scrollToTop();
                });
              },
            ),
          ...List.generate(endPage - startPage + 1, (index) {
            int pageNumber = startPage + index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      currentPage == pageNumber ? Colors.blue : Colors.grey,
                  minimumSize: const Size(40, 40),
                ),
                onPressed: () {
                  setState(() {
                    currentPage = pageNumber;
                    _scrollToTop();
                  });
                },
                child: Text('$pageNumber'),
              ),
            );
          }),
          if (endPage < totalPages)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  currentPage = endPage + 1;
                  _scrollToTop();
                });
              },
            ),
        ],
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}
