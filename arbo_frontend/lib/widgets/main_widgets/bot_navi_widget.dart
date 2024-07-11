import 'package:arbo_frontend/data/history_data.dart';
import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/roots/root_screen.dart';
import 'package:arbo_frontend/screens/create_post_screen.dart';
import 'package:arbo_frontend/screens/specific_post_screen.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:flutter/material.dart';

class BotNaviWidget extends StatefulWidget {
  final VoidCallback refreshDataCallback;
  final Map<String, dynamic>? postData;
  final VoidCallback onPreviousPage; // Add this parameter

  const BotNaviWidget({
    super.key,
    required this.postData,
    required this.refreshDataCallback,
    required this.onPreviousPage,
  });

  @override
  State<BotNaviWidget> createState() => _BotNaviWidgetState();
}

class _BotNaviWidgetState extends State<BotNaviWidget> {
  DateTime? lastRefreshTime;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _navigateToScreen(String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  void _previousPage() async {
    Navigator.pop(context, widget.postData);
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

  void refreshPage() {
    DateTime now = DateTime.now();
    if (lastRefreshTime == null ||
        now.difference(lastRefreshTime!).inSeconds >= 30) {
      lastRefreshTime = now;
      widget.refreshDataCallback();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('새로고침은 30초에 한 번만 가능합니다.'),
        ),
      );
    }
  }

  void _checkAndNavigateToCreatePost() async {
    if (currentLoginUser != null) {
      final result = await Navigator.pushNamed(
        context,
        CreatePostScreen.routeName,
      );

      // If the result is true, refresh the posts
      if (result == true) {
        widget.refreshDataCallback();
      }
      // _navigateToScreen(CreatePostScreen.routeName);
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
            } else if (page_location == 0) {
              // widget.onPreviousPage;
              selectedIndex = -1;
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const RootScreen()));
            }
            break;
          case 1:
            if (page_location < pageList.length) {
              page_location++;
              _nextPage();
            }
            break;
          case 2:
            refreshPage();
            break;
          case 3:
            _checkAndNavigateToCreatePost();
            break;
        }
      },
    );
  }
}
