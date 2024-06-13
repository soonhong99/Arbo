import 'package:arbo_frontend/resources/user_data_provider.dart';
import 'package:arbo_frontend/resources/user_data.dart';
import 'package:arbo_frontend/screens/user_info_screen.dart';
import 'package:arbo_frontend/widgets/main_widgets/appbar_widget.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/bot_navi_widget.dart';
import 'package:arbo_frontend/rootscreen/main_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // listen: true이므로 만약 userData가 바뀌었다면 싹다 rebuild
    final userData = Provider.of<UserDataProvider>(context);

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
            CustomSliverAppBar(
              user: currentLoginUser,
              nickname: nickname,
              onLogout: () {
                // 로그아웃 로직
                auth.signOut();
                userData.fetchLoginUserData(null);
                likedPosts = [];
              },
              onLogin: () {
                // 로그인 로직
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return LoginPopupWidget(
                      onLoginSuccess: () {},
                    );
                  },
                );
              },
              onUserInfo: () {
                // 사용자 정보 보기 로직
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return UserInfoScreen(
                      user: currentLoginUser,
                    );
                  },
                );
              },
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
      // bottomNavigationBar: const BotNaviWidget(
      //   postData: null,
      // ),
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
