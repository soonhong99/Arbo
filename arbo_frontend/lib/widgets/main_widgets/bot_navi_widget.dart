import 'package:arbo_frontend/resources/history_data.dart';
import 'package:arbo_frontend/screens/create_post_screen.dart';
import 'package:arbo_frontend/screens/specific_post_screen.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BotNaviWidget extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const BotNaviWidget({super.key, this.onLoginSuccess});

  @override
  State<BotNaviWidget> createState() => _BotNaviWidgetState();
}

class _BotNaviWidgetState extends State<BotNaviWidget> {
  void _navigateToScreen(String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  void _previousPage() {
    setState(() {
      Navigator.pop(context);
    });
  }

  void _nextPage() {
    setState(() {
      final lastVisitedPage = getLastVisitedPage();
      // lastVistedPage는 정확한데 여기서 argument가 다른 것이 들어간다.
      if (lastVisitedPage != null && page_location <= pageList.length) {
        Navigator.pushNamed(
          context,
          SpecificPostScreen.routeName,
          arguments: lastVisitedPage,
        );
      }
    });
  }

  void _refreshPage() {
    setState(() {
      // 현재 페이지를 다시 그립니다.
    });
  }

  Future<void> _checkAndNavigateToCreatePost() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _navigateToScreen(CreatePostScreen.routeName);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return LoginPopupWidget(
            onLoginSuccess: (user) {
              // 로그인되어서 user 갖고왔으니까 부모한테 callback
              widget.onLoginSuccess?.call();
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.blue,
          ),
          label: 'Previous',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.arrow_forward,
            color: Colors.blue,
          ),
          label: 'Next',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.refresh,
            color: Colors.blue,
          ),
          label: 'Refresh',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.create,
            color: Colors.blue,
          ),
          label: 'Write',
        ),
      ],
      onTap: (index) {
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
              print('다음 페이지로 갑니다 $page_location');
              _nextPage();
            }
            break;
          case 2:
            _refreshPage();
            break;
          case 3:
            _checkAndNavigateToCreatePost();
            break;
        }
      },
    );
  }
}
