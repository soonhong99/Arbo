import 'package:arbo_frontend/resources/user_data.dart';
import 'package:arbo_frontend/resources/user_data_provider.dart';
import 'package:arbo_frontend/screens/user_info_screen.dart';
import 'package:arbo_frontend/widgets/main_widgets/appbar_widget.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:arbo_frontend/roots/main_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  NavigationState _currentNavigationState = NavigationState.initial;

  void _onCategoryTapped(int index) {
    setState(() {
      selectedIndex = index;
      _currentNavigationState = NavigationState.main;
    });
  }

  void _navigateBackToInitial() {
    setState(() {
      selectedIndex = -1;
      _currentNavigationState = NavigationState.initial;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);

    final List<Map<String, String>> furnitureCategories = [
      {'name': '의자', 'image': 'images/categorized/chair.png'},
      {'name': '테이블', 'image': 'images/categorized/table.png'},
      {'name': '소파', 'image': 'images/categorized/sofa.png'},
      {'name': '침대', 'image': 'images/categorized/bed.png'},
      {'name': '수납장', 'image': 'images/categorized/storage.png'},
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
            ),
          ];
        },
        body: _currentNavigationState == NavigationState.initial
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '디자인 프롬프트 입력',
                      ),
                      onSubmitted: (String value) {
                        // 사용자가 프롬프트를 입력하고 제출했을 때의 동작
                        print('User entered prompt: $value');
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: furnitureCategories.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _onCategoryTapped(index);
                          },
                          child: Column(
                            children: [
                              Image.asset(
                                furnitureCategories[index]['image']!,
                                width: 200,
                                height: 200,
                              ),
                              Text(furnitureCategories[index]['name']!),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Text('화면에 있는 UI들 간격 조정'),
                  const Text('아래에 핫한 디자인, 최근 디자인 simple widget 넣을 것'),
                  const Text('가구 종류를 클릭하면 해당 종류에 맞는 디자인만 선별해서 보여줄 것'),
                ],
              )
            : MainWidget(
                onPreviousPage: _navigateBackToInitial,
              ),
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
              selected: selectedIndex == 0,
              onTap: () {
                _onCategoryTapped(0);
                Navigator.pop(context);
              },
            ),
            navigationToggle(context, '대자보'),
            navigationToggle(context, '소자보')
          ],
        ),
      ),
    );
  }

  ExpansionTile navigationToggle(BuildContext context, String postSize) {
    return ExpansionTile(
      title: Text(postSize),
      initiallyExpanded: selectedIndex == 1,
      children: [
        ListTile(
          title: const Text('자유'),
          onTap: () {
            _onCategoryTapped(1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('정치'),
          onTap: () {
            _onCategoryTapped(1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('경제'),
          onTap: () {
            _onCategoryTapped(1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('사회'),
          onTap: () {
            _onCategoryTapped(1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('정보'),
          onTap: () {
            _onCategoryTapped(1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: const Text('호소'),
          onTap: () {
            _onCategoryTapped(1);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

enum NavigationState { initial, main }
