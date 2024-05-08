import 'package:arbo_frontend/widgets/post_widgets/humor_post_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arbo_frontend/widgets/main_widgets/key_board_trigger_widget.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KeyBoardTrigger(
                labelText: '검색할 나무를 입력하세요',
                screenWidth: screenWidth,
              ),
              const SizedBox(
                width: 10,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        Expanded(
          child: hotPost(screenWidth),
        ),
      ],
    );
  }

  ListView hotPost(double screenWidth) {
    return ListView.separated(
      scrollDirection: Axis.vertical,
      separatorBuilder: (context, index) => const SizedBox(
        height: 100,
      ),
      itemCount: 5, // hardcoding
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100),
          child: Column(
            children: [
              HumorPostWidget(
                nickname: 'User123',
                thumbnailUrl: 'https://example.com/thumbnail.jpg',
                title: '유머 게시물 제목',
                content:
                    '유머 게시물 내용입니다. 매우 유머스럽습니다. 미ㅏㄴ어뢰마너오리ㅏㅓㅁ농라몬ㅇ리ㅏㅓㅗㅁㄴ이ㅏㅓ롬니ㅏ어ㅗ리ㅏㅁ너오리ㅏㅓㅁ농리ㅏㅓㅗㅁㄴ이라ㅓㅗㅁ니아ㅓ룀나어ㅗㄹ ㅁㄴ이;ㅏ러;ㄴ미아ㅓㄹ;ㅏㅣㅁ넝ㄹ;ㅏㅣ먼ㅇ;리ㅏㅓㅁㄴㅇ;ㅣㅏ럼ㄴ; ㅏㅣ어라ㅣ;ㅁ넝리;ㅏㅓ ㅁㄴ;ㅣㅏ얼 ;ㅣㅏㅁ넝라ㅣ;ㅓ ㅁㄴ;ㅏㅣ얼;ㅣㅏㅓ ㅁㄴ;ㅏㅣ얼;ㅏㅣㅓㅁㄴ ㅏㅣ;어라ㅣ;ㅓㅁㄴ ;이ㅏ러ㅏㅣ;ㅁ넝 ;ㅏㅣ럼ㄴ;ㅏㅣ얼;ㅣㅏ 먼ㅇ',
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
