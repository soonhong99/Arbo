import 'package:arbo_frontend/resources/user_data.dart';
import 'package:arbo_frontend/resources/user_data_provider.dart';
import 'package:arbo_frontend/roots/simple_post_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/bot_navi_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MainWidget extends StatefulWidget {
  final VoidCallback onPreviousPage;

  const MainWidget({
    super.key,
    required this.onPreviousPage,
  });

  @override
  State<MainWidget> createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> {
  List<String> categories = ['전체', '자유', '정치', '경제', '사회', '정보', '호소'];
  List<String> updatedTime = ['지난 1일', '지난 1주', '지난 1개월', '지난 1년', '전체'];
  String selectedCategory = '전체'; // 초기에는 전체 카테고리를 선택합니다.
  String selectedUpdatedTime = '지난 1개월';
  bool showAllCategories = false; // 초기에는 전체 카테고리를 숨깁니다.
  final UserDataProvider userDataProvider = UserDataProvider();
  late Future<void> _fetchDataFuture; // 데이터 fetch를 위한 Future

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = userDataProvider.fetchPostData();
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

    return postListSnapshot.where((post) {
      bool matchesCategory =
          selectedCategory == '전체' || post['topic'] == selectedCategory;
      bool matchesTime =
          (post['timestamp'] as Timestamp).toDate().isAfter(cutoff);
      return matchesCategory && matchesTime;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.1;

    return Scaffold(
      body: FutureBuilder(
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
                      const SizedBox(width: 10), // Adjust as needed for spacing
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () {
// 최신 버튼이 클릭되었을 때의 동작
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.noise_aware_sharp),
                                  Text('최신'),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
// 인기 버튼이 클릭되었을 때의 동작
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.fire_hydrant_alt_sharp),
                                  Text('인기'),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
// 베스트 버튼이 클릭되었을 때의 동작
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.local_fire_department_sharp),
                                  Text('베스트'),
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
      bottomNavigationBar: BotNaviWidget(
        postData: null,
        refreshDataCallback: () {
          _refreshData();
        },
        onPreviousPage: widget.onPreviousPage, // Pass the callback
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
