import 'package:arbo_frontend/resources/previous_data.dart';
import 'package:arbo_frontend/screens/specific_post_screen.dart';
import 'package:flutter/material.dart';

class BotNaviWidget extends StatefulWidget {
  const BotNaviWidget({
    super.key,
  });

  @override
  State<BotNaviWidget> createState() => _BotNaviWidgetState();
}

class _BotNaviWidgetState extends State<BotNaviWidget> {
  // 이전 페이지로 이동 fix it
  // 인자로 전달된 전 페이지로 넘어간다.
  void _previousPage() {
    setState(() {
      Navigator.pop(context);
      if (page_location != 0) {
        page_location--;
      }
      print(
          'page location: $page_location, page length: ${previousPageList.length}');
    });
  }

  // 다음 페이지로 이동 fix it
  void _nextPage() {
    setState(() {
      final lastVisitedPage = getNextVisitedPage();
      if (lastVisitedPage != null && page_location != previousPageList.length) {
        Navigator.pushNamed(
          context,
          SpecificPostScreen.routeName,
          arguments: lastVisitedPage,
        );
        page_location++;
        print(
            'page location: $page_location, page length: ${previousPageList.length}');
      }
    });
  }

  // 현재 페이지 새로 고침
  void _refreshPage() {
    setState(() {
      // 현재 페이지를 다시 그립니다.
    });
    print('way!');
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(
            Icons.arrow_back,
            color: page_location == 0 ? Colors.grey : Colors.blue,
          ),
          label: 'Previous',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.arrow_forward,
            color: (page_location == previousPageList.length ||
                    previousPageList.isEmpty)
                ? Colors.grey
                : Colors.blue,
          ),
          label: 'Next',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.refresh),
          label: 'Refresh',
        ),
      ],
      selectedItemColor: Colors.blue,
      onTap: (index) {
        // 각 버튼에 대한 탭 핸들러
        switch (index) {
          case 0:
            if (page_location != 0) {
              _previousPage();
            }
            break;
          case 1:
            if (page_location < previousPageList.length) {
              _nextPage();
            }
            break;
          case 2:
            _refreshPage();
            break;
        }
      },
    );
  }
}
