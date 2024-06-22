import 'package:arbo_frontend/resources/user_data.dart';
import 'package:arbo_frontend/widgets/main_widgets/design_prompt_dialog_widget.dart';
import 'package:arbo_frontend/widgets/main_widgets/design_prompt_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbo_frontend/resources/user_data_provider.dart';
import 'package:arbo_frontend/screens/user_info_screen.dart';
import 'package:arbo_frontend/widgets/main_widgets/appbar_widget.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:arbo_frontend/roots/main_widget.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  NavigationState _currentNavigationState = NavigationState.initial;
  int selectedIndex = -1; // Added to fix selectedIndex reference
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _promptController = TextEditingController();
  bool firstClickedPrompt = true;

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

  void _showPromptDialog() {
    if (firstClickedPrompt) {
      promptSearchHistory = loginUserData!['프롬프트 기록'] ?? [];
      firstClickedPrompt = false;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DesignPromptDialog(
          promptController: _promptController,
          searchHistory: promptSearchHistory,
          onSearch: (searchTerm) async {
            if (searchTerm.isNotEmpty) {
              // Add to search history
              if (promptSearchHistory.length >= 3) {
                promptSearchHistory.removeAt(0);
              }
              promptSearchHistory.add(searchTerm);

              // Save to Firebase
              await saveSearchHistoryToFirebase(promptSearchHistory);

              // Perform search logic here
              // performSearch(searchTerm);
            }
          },
        );
      },
    );
  }

  Future<void> saveSearchHistoryToFirebase(List<dynamic> searchHistory) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'프롬프트 기록': searchHistory});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);

    final List<Map<String, String>> furnitureCategories = [
      {'name': '전체', 'image': 'images/categorized/all.png'},
      {'name': 'NoLimit', 'image': 'images/categorized/nolimit.png'},
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
                    child: DesignPromptWidget(
                      onPromptTap: () {
                        if (currentLoginUser != null) {
                          _showPromptDialog();
                        } else {
                          // 로그인 유도
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return LoginPopupWidget(
                                onLoginSuccess: () {},
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        _scrollController.jumpTo(
                            _scrollController.offset - details.delta.dx);
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: furnitureCategories.length,
                        separatorBuilder: (context, index) => const SizedBox(
                          width: 40,
                        ),
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
                  ),
                  const Text('화면에 있는 UI들 간격 조정'),
                  const Text('아래에 핫한 디자인, 최근 디자인 simple widget 넣을 것'),
                  const Text('가구 종류를 클릭하면 해당 종류에 맞는 디자인만 선별해서 보여줄 것'),
                ],
              )
            : MainWidget(
                onPreviousPage: _navigateBackToInitial,
                initialCategory: furnitureCategories[selectedIndex]
                    ['name']!, // Pass the selected category
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

  // 현재 안쓰는중.
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
