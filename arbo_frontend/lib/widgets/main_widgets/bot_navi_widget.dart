import 'package:arbo_frontend/resources/history_data.dart';
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
      print('page location: $page_location, page length: ${pageList.length}');
    });
  }

  // 다음 페이지로 이동 fix it
  void _nextPage() {
    setState(() {
      // lastVisitedPage: 아직 page location이 바뀌기 전이므로 바로 전 페이지의 값들을 갖고 있다.
      final lastVisitedPage = getLastVisitedPage();

      if (lastVisitedPage != null && page_location <= pageList.length) {
        Navigator.pushNamed(
          context,
          SpecificPostScreen.routeName,
          arguments: lastVisitedPage,
        );
      }
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
            color: (page_location == pageList.length || pageList.isEmpty)
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
              page_location--;
              _previousPage();
            }
            break;
          case 1:
            if (page_location < pageList.length) {
              page_location++;
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
