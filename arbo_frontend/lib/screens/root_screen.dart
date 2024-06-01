import 'package:arbo_frontend/resources/user_data.dart';
import 'package:arbo_frontend/screens/user_info_screen.dart';
import 'package:arbo_frontend/widgets/main_widgets/app_state.dart';
import 'package:arbo_frontend/widgets/main_widgets/appbar_widget.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/bot_navi_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/main_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  bool _isLoading = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // // widget화 필요
  // void updateNickname(User? user) async {
  //   if (user != null) {
  //     // Fetch the user's nickname from Firestore
  //     DocumentSnapshot userDoc = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user.uid)
  //         .get();
  //     setState(() {
  //       _nickname = userDoc['닉네임'];
  //     });
  //   } else {
  //     setState(() {
  //       _nickname = null;
  //     });
  //   }
  // }

  void updateNickname(User? user) async {
    // Set loading state to true
    setState(() {
      _isLoading = true;
    });

    if (user != null) {
      // Fetch the user's nickname from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        nickname = userDoc['닉네임'];
      });
    } else {
      setState(() {
        nickname = '';
      });
    }

    // Set loading state to false after data is fetched
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);
    final user = userData.user;
    final List<Widget> widgetOptions = <Widget>[
      const MainWidget(),
      const Text('Index 1: 대자보'),
      const Text('Index 2: 소자보'),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return <Widget>[
                  CustomSliverAppBar(
                    user: user,
                    nickname: nickname,
                    onLogout: () {
                      // 로그아웃 로직
                      FirebaseAuth.instance.signOut();
                      userData.updateUser(null);
                    },
                    onLogin: () {
                      // 로그인 로직
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return LoginPopupWidget(
                            onLoginSuccess: (user) {
                              userData.updateUser(user);
                              userData.updateNickname(nickname);
                              print('nickname root: $nickname');
                              updateNickname(user);
                            },
                          );
                        },
                      );
                    },
                    onUserInfo: () {
                      // 사용자 정보 보기 로직
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return UserInfoScreen(user: user!);
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
