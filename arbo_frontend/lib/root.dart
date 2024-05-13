import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'screens/main_screen.dart';

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  // home page, 대자보 page, 소자보 page구분.
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // fix it
  static final List<Widget> _pages = <Widget>[
    const Text('Home'),
    const Text('Search'),
    const Text('Profile'),
  ];

  // 이전 페이지로 이동 fix it
  void _previousPage() {
    setState(() {
      if (_selectedIndex > 0) {
        _selectedIndex--;
      } else {
        // 이전 페이지가 없으면 현재 페이지를 팝하여 이전 화면으로 이동합니다.
        Navigator.pop(context);
      }
      print(_selectedIndex);
    });
  }

  // 다음 페이지로 이동 fix it
  void _nextPage() {
    setState(() {
      if (_selectedIndex < _pages.length - 1) {
        _selectedIndex++;
      }
      print(_selectedIndex);
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
    // 현재 화면의 가로 길이
    final List<Widget> widgetOptions = <Widget>[
      const MainScreen(),
      const Text(
        'Index 1: 대자보',
      ),
      const Text(
        'Index 2: 소자보',
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              snap: true,
              foregroundColor: Colors.green,
              title: Row(
                children: [
                  const Text('자보'),
                  const Spacer(), // 띄어쓰기

                  TextButton(
                    onPressed: () {
                      // 마이페이지 버튼을 눌렀을 때 로그인 창을 팝업으로 표시합니다.
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const LoginPopupWidget(); // LoginPage 위젯을 반환합니다.
                        },
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.person),
                        Text('마이페이지'),
                      ],
                    ),
                  )
                ],
              ),
            )
          ];
        },
        body: widgetOptions[_selectedIndex],
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                // Update the state of the app
                _onItemTapped(0);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            navigation_toggle(context, '대자보'),
            navigation_toggle(context, '소자보')
          ],
        ),
      ),
      bottomNavigationBar: InitializeBotNavi(),
    );
  }

  BottomNavigationBar InitializeBotNavi() {
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
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.blue,
      onTap: (index) {
        // 각 버튼에 대한 탭 핸들러
        switch (index) {
          case 0:
            _previousPage();
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

  ExpansionTile navigation_toggle(BuildContext context, String postSize) {
    return ExpansionTile(
      title: Text(postSize),
      initiallyExpanded:
          _selectedIndex == 1, // Adjust initial expansion based on selection
      children: [
        ListTile(
          title: const Text('정치'),
          onTap: () {
            _onItemTapped(1); // Adjust index based on selected category
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('경제'),
          onTap: () {
            _onItemTapped(1); // Adjust index based on selected category
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('사회'),
          onTap: () {
            _onItemTapped(1); // Adjust index based on selected category
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('정보'),
          onTap: () {
            _onItemTapped(1); // Adjust index based on selected category
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('호소'),
          onTap: () {
            _onItemTapped(1); // Adjust index based on selected category
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
