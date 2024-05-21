import 'package:arbo_frontend/widgets/User_widgets/user_info_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/main_widget.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/bot_navi_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;
  User? _user; // Firebase user object to track authentication state

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _previousPage() {
    setState(() {
      if (_selectedIndex > 0) {
        _selectedIndex--;
      } else {
        Navigator.pop(context);
      }
    });
  }

  void _nextPage() {
    setState(() {
      if (_selectedIndex < _pages.length - 1) {
        _selectedIndex++;
      }
    });
  }

  void _refreshPage() {
    setState(() {
      // Refresh current page
    });
  }

  static final List<Widget> _pages = <Widget>[
    const Text('Home'),
    const Text('Search'),
    const Text('Profile'),
  ];

  void _updateUser(User? user) {
    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      const MainWidget(),
      const Text('Index 1: 대자보'),
      const Text('Index 2: 소자보'),
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
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      if (_user == null) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return LoginPopupWidget(
                              onLoginSuccess: (user) {
                                _updateUser(user);
                              },
                            );
                          },
                        );
                      } else {
                        // Display user information
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return UserInfoWidget(user: _user!);
                          },
                        );
                      }
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
        child: ListView(
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
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            navigation_toggle(context, '대자보'),
            navigation_toggle(context, '소자보')
          ],
        ),
      ),
      bottomNavigationBar: const BotNaviWidget(),
    );
  }

  ExpansionTile navigation_toggle(BuildContext context, String postSize) {
    return ExpansionTile(
      title: Text(postSize),
      initiallyExpanded: _selectedIndex == 1,
      children: [
        ListTile(
          title: const Text('자유'),
          onTap: () {
            _onItemTapped(1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('정치'),
          onTap: () {
            _onItemTapped(1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('경제'),
          onTap: () {
            _onItemTapped(1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('사회'),
          onTap: () {
            _onItemTapped(1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('정보'),
          onTap: () {
            _onItemTapped(1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('호소'),
          onTap: () {
            _onItemTapped(1);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
