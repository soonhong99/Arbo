import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../widgets/main_widgets/main_Appbar_widget.dart';
import 'main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    MainScreen(),
    Text(
      'Index 1: Business',
    ),
    Text(
      'Index 2: School',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 현재 화면의 가로 길이
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                foregroundColor: Colors.green,
                title: Row(
                  children: [
                    const Text('Weight Tracker'),
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
                    )
                  ],
                ),
              )
            ];
          },
          body: _widgetOptions[_selectedIndex]),
      // appBar: AppBar(
      //   // automaticallyImplyLeading: false, // 뒤로 가기 버튼 사용 유무
      //   surfaceTintColor: Colors.white,
      //   shadowColor: Colors.black,
      //   elevation: 2,
      //   foregroundColor: Colors.green,
      //   // toolbarHeight: 180, // toolbar의 height -> 나중에 비율화 해야된다.

      //   title: Padding(
      //     // leading: title을 실행하기전에 보이는 아이콘이나 아이콘 버튼
      //     padding: const EdgeInsets.all(8.0),
      //     child: Row(
      //       mainAxisAlignment: MainAxisAlignment.start,
      //       children: [
      //         const Text(
      //           '옹기종기',
      //           style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
      //         ),
      //         const Spacer(), // 띄어쓰기
      //         TextButton(
      //           onPressed: () {
      //             // Navigate to MyPage
      //             Navigator.pushNamed(context,
      //                 '/myPage'); // Replace with your actual route name
      //           },
      //           child: const Row(
      //             children: [
      //               Icon(Icons.person),
      //               Text('마이페이지'),
      //             ],
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
      //MainAppBar(screenWidth: screenWidth),
      // body: _widgetOptions[_selectedIndex],
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
            ListTile(
              title: const Text('Business'),
              selected: _selectedIndex == 1,
              onTap: () {
                // Update the state of the app
                _onItemTapped(1);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('School'),
              selected: _selectedIndex == 2,
              onTap: () {
                // Update the state of the app
                _onItemTapped(2);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
