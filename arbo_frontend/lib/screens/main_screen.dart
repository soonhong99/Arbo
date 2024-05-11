import 'package:arbo_frontend/widgets/post_widgets/simple_post_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arbo_frontend/widgets/main_widgets/key_board_trigger_widget.dart';

class MainScreen extends StatefulWidget {
  final Widget bottomNavigationBar;
  const MainScreen({
    super.key,
    required this.bottomNavigationBar,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<String> categories = ['전체', '정치', '경제', '사회', '정보', '호소'];
  List<String> updatedTime = ['지난 1일', '지난 1주', '지난 1개월', '지난 1년', '전체'];
  String selectedCategory = '전체'; // 초기에는 전체 카테고리를 선택합니다.
  String selectedUpdatedTime = '지난 1개월';
  bool showAllCategories = false; // 초기에는 전체 카테고리를 숨깁니다.
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.1;

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
                items: categories.map<DropdownMenuItem<String>>((String value) {
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
                items:
                    updatedTime.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              // 검색 필드와 검색 버튼
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    KeyBoardTrigger(
                      labelText:
                          showAllCategories ? '검색할 나무를 입력하세요' : '카테고리 선택',
                      screenWidth: screenWidth,
                    ),
                    const SizedBox(height: 10),
                    IconButton(
                      onPressed: () {
                        // 검색 버튼이 눌렸을 때의 동작
                      },
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
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
        Expanded(
          child: Post(screenWidth, horizontalPadding),
        ),
      ],
    );
  }

  ListView Post(double screenWidth, double horizontalPadding) {
    return ListView.separated(
      scrollDirection: Axis.vertical,
      separatorBuilder: (context, index) => const SizedBox(
        height: 100,
      ),
      itemCount: 5, // hardcoding
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              SimplePostWidget(
                bottomNavigationBar: widget.bottomNavigationBar,
                postTopic: '경제',
                nickname: '난나야',
                //thumbnailUrl: '',
                title: '더현대 대구 5월 팝업 후토마끼가 맛있는 분위기 좋은 일식 맛집 초이다이닝',
                content:
                    '오늘은 더현대 대구 5월 팝업도 둘러볼 겸 백화점에 다녀왔는데요. 각층마다 다양한 팝업이 있어 구경하다 보니 배가 고파서 지하 푸드코트에 후토마끼 맛있기로 유명한 초이다이닝에 찾아갔어요. ',
                likes: 10,
                comments: 5,
                timestamp: DateTime.now(),
              ),
              const SizedBox(
                height: 50,
              ),
              Container(
                height: 500,
                color: Colors.green[100],
                child: const Center(child: Text('쓸모있죠?')),
              ),
              const SizedBox(
                height: 50,
              ),
              Container(
                height: 500,
                color: Colors.green[300],
                child: const Center(child: Text('의견이 필요해요')),
              ),
              const SizedBox(
                height: 50,
              ),
              Container(
                height: 500,
                color: Colors.green[500],
                child: const Center(child: Text('공감해줘요')),
              ),
            ],
          ),
        );
      },
    );
  }
}
