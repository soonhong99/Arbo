import 'package:arbo_frontend/resources/previous_data.dart';
import 'package:flutter/material.dart';

class BotNaviWidget extends StatefulWidget {
  const BotNaviWidget({
    super.key,
  });

  @override
  State<BotNaviWidget> createState() => _BotNaviWidgetState();
}

class _BotNaviWidgetState extends State<BotNaviWidget> {
  // pageCount는 list의 length로 하자
  // pagePrevious는 page의 list를 만들어서 해당 list를 꺼내서 쓰는 방식으로 구현
  String pagePrevious = previousPageList.last;
  int pageCount = previousPageList.length;

  // 이전 페이지로 이동 fix it
  // 인자로 전달된 전 페이지로 넘어간다.
  void _pageCount() {
    setState(() {
      pageCount--;
      Navigator.pop(context);
      print(pageCount);
    });
  }

  // 다음 페이지로 이동 fix it
  void _nextPage() {
    setState(() {
      pageCount++;
      print(pageCount);
    });
  }

  // 현재 페이지 새로 고침
  void _refreshPage() {
    setState(() {
      // 현재 페이지를 다시 그립니다.
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.arrow_back),
          label: 'Previous',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.arrow_forward),
          label: 'Next',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.refresh),
          label: 'Refresh',
        ),
      ],
      currentIndex: pageCount,
      selectedItemColor: Colors.blue,
      onTap: (index) {
        // 각 버튼에 대한 탭 핸들러
        switch (index) {
          case 0:
            _pageCount();
            break;
          case 1:
            _nextPage();
            break;
          case 2:
            _refreshPage();
            break;
        }
      },
    );
  }
}
