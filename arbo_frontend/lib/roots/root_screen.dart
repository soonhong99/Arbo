import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/design/paint_stroke.dart';
import 'package:arbo_frontend/roots/my_post_in_root.dart';
import 'package:arbo_frontend/widgets/gemini_widgets/gemini_advisor_chat.dart';
import 'package:arbo_frontend/widgets/prompt_widgets/prompt_dialog_widget.dart';
import 'package:arbo_frontend/widgets/prompt_widgets/prompt_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_geocoding/google_geocoding.dart';
import 'package:provider/provider.dart';
import 'package:arbo_frontend/data/user_data_provider.dart';
import 'package:arbo_frontend/screens/user_info_screen.dart';
import 'package:arbo_frontend/roots/appbar_widget.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:arbo_frontend/roots/main_widget.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  bool _isLoading = false;

  NavigationState _currentNavigationState = NavigationState.initial;
  int selectedIndex = -1; // Added to fix selectedIndex reference
  final ScrollController _scrollController = ScrollController();
  bool firstClickedPrompt = true;

  Future<void> _getLocationPermission() async {
    setState(() {
      _isLoading = true;
      locationMessage = '위치 정보를 가져오는 중...';
    });

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        _isLoading = false;
        locationMessage = '위치 권한이 거부되었습니다.';
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        locationMessage = '위치 권한이 영구적으로 거부되었습니다.';
      });
      return;
    }

    _getLocation();
  }

  Future<void> _getLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    var response = await googleGeocoding.geocoding
        .getReverse(LatLon(position.latitude, position.longitude));

    if (response != null && response.results != null) {
      final geocodingResponse = response.results;
      if (geocodingResponse != null) {
        address = geocodingResponse[0].formattedAddress!;
        setState(
          () {
            _isLoading = false;
            // locationMessage = address;
            List<String> addressComponents = address.split(' ');
            if (addressComponents.length >= 3) {
              country = addressComponents[0];
              city = addressComponents[1];
              district = addressComponents[2];

              // Combine the components for the location message
              locationMessage = '$country, $city, $district';
            }
          },
        );
      } else {
        setState(() {
          _isLoading = false;
          locationMessage = '지명 정보를 가져오지 못했습니다.';
        });
      }
    }
  }

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

    final vertexAI = FirebaseVertexAI.instanceFor(
        location: 'asia-northeast3', appCheck: firebase_appcheck_instance);

    final generationConfig = GenerationConfig(
        maxOutputTokens: 200,
        stopSequences: ["red"],
        temperature: 1,
        topP: 0.95,
        topK: 40,
        responseMimeType: "text/plain");

    final model = vertexAI.generativeModel(
      // model: 'gemini-1.5-flash',
      model: 'gemini-1.5-pro',
      generationConfig: generationConfig,
      systemInstruction: Content.system(community_advisor_instructions),
    );

    ChatSession chatSession =
        model.startChat(history: community_advisor_initialHistory);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PromptDialog(
          vertexAIModel: model,
          promptController: TextEditingController(),
          onSendMessage: (String message) async {
            // VertexAI 모델을 사용하여 응답 생성
            var content = Content.text(message);
            try {
              var response = await chatSession.sendMessage(content);
              return response.text;
            } catch (e) {
              print(e);
              return "Sorry, I couldn't process that. Can you try again?";
            }
          },
          initializeChat: () async {
            // 여기에 필요한 초기화 작업을 수행합니다.
            // 예: VertexAI 모델 초기화, 채팅 세션 시작 등
            await Future.delayed(const Duration(seconds: 2)); // 예시용 지연
          },
        );
      },
    );
  }

  Future<void> saveSearchHistoryToFirebase(List<dynamic> searchHistory) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await firestore_instance
          .collection('users')
          .doc(userId)
          .update({'프롬프트 기록': searchHistory});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);

    final List<Map<String, String>> furnitureCategories = [
      {'name': 'All posts', 'image': 'images/categorized/all_posts.png'},
      {
        'name': 'Education and Development',
        'image': 'images/categorized/Education_and_Youth_Development.png'
      },
      {
        'name': 'Improving Facilites',
        'image':
            'images/categorized/Expanding_local_hospitals_and_medical_facilities.png'
      },
      {
        'name': 'Recycling Management',
        'image': 'images/categorized/Recycling_and_waste_management.png'
      },
      {
        'name': 'Crime Prevention',
        'image': 'images/categorized/Crime_Prevention_Program.png'
      },
      {
        'name': 'Local Commercial',
        'image':
            'images/categorized/Revitalizing_local_commercial_districts.JPG'
      },
      {
        'name': 'Local Events',
        'image': 'images/categorized/Local festivals and cultural events.JPG'
      },
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
            ? Stack(
                children: [
                  // 배경으로 _strokes 그리기
                  CustomPaint(
                    painter: StrokePainter(userPaintBackGround),
                    size: Size.infinite,
                  ),
                  SingleChildScrollView(
                      child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(50.0),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : locationMessage == '위치 정보를 가져오는 중...' ||
                                    locationMessage == '위치 권한이 거부되었습니다.' ||
                                    locationMessage ==
                                        '위치 권한이 영구적으로 거부되었습니다.' ||
                                    locationMessage == '지명 정보를 가져오지 못했습니다.' ||
                                    firstLocationTouch
                                ? ElevatedButton(
                                    onPressed: () {
                                      _getLocationPermission();
                                      firstLocationTouch = false;
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.all(16.0),
                                      backgroundColor: Colors.blue.shade100,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(locationMessage),
                                  )
                                : Text(
                                    'You live in $locationMessage! Let\'s paint your community!',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[800]),
                                  ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.purple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: PromptBar(
                            onPromptTap: () {
                              if (currentLoginUser != null) {
                                _showPromptDialog();
                              } else {
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
                      ),
                      const SizedBox(height: 20),
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
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 40),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  _onCategoryTapped(index);
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value: 0.7,
                                            backgroundColor: Colors.grey[300],
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(Colors.blue),
                                          ),
                                          ClipOval(
                                            child: Image.asset(
                                              furnitureCategories[index]
                                                  ['image']!,
                                              width: 180,
                                              height: 180,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      furnitureCategories[index]['name']!,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const MyPostsInRoot(
                        postsTitle: '내 게시판',
                        notLoginInfo: '로그인하여 나만의 게시판을 확인하세요.',
                        mypost: true,
                      ),
                      const SizedBox(height: 50),
                      const MyPostsInRoot(
                        postsTitle: '참여하는 게시판',
                        notLoginInfo: '로그인하여 내가 참여한 게시판을 확인하세요.',
                        mypost: false,
                      ),
                      const SizedBox(height: 200),
                    ],
                  )),
                ],
              )
            : MainWidget(
                onPreviousPage: _navigateBackToInitial,
                initialCategory: furnitureCategories[selectedIndex]
                    ['name']!, // Pass the selected category
              ),
      ),
    );
  }
}

enum NavigationState { initial, main }
