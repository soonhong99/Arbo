import 'package:arbo_frontend/screens/navigation_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'key_board_trigger_widget.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    required this.screenWidth,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(appBarHeight); // Define desired height

  final double appBarHeight = 200;

  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // 뒤로 가기 버튼 사용 유무
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black,
      elevation: 2,
      foregroundColor: Colors.green,
      toolbarHeight: 180, // toolbar의 height -> 나중에 비율화 해야된다.
      leadingWidth: screenWidth,
      leading: Padding(
        // title을 실행하기전에 보이는 아이콘이나 아이콘 버튼
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Arbo Logo',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                ),
                const Spacer(), // 띄어쓰기
                TextButton(
                  onPressed: () {
                    // Navigate to MyPage
                    Navigator.pushNamed(context,
                        '/myPage'); // Replace with your actual route name
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.person),
                      Text('마이페이지'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 50,
            ),
            Row(
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
          ],
        ),
      ),
    );
  }
}
