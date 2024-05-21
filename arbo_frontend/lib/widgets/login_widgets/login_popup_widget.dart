// import 'package:arbo_frontend/widgets/login_widgets/signup_popup_widget.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// class LoginPopupWidget extends StatelessWidget {
//   const LoginPopupWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('로그인'),
//       content: const SingleChildScrollView(
//         child: ListBody(
//           children: <Widget>[
//             TextField(
//               decoration: InputDecoration(
//                 labelText: '이메일',
//                 hintText: 'example@example.com',
//               ),
//             ),
//             TextField(
//               obscureText: true,
//               decoration: InputDecoration(
//                 labelText: '비밀번호',
//               ),
//             ),
//           ],
//         ),
//       ),
//       actions: <Widget>[
//         TextButton(
//           child: const Text('로그인'),
//           onPressed: () {
//             // 여기에 로그인 기능을 구현하세요.
//           },
//         ),
//         TextButton(
//           child: const Text('회원가입'),
//           onPressed: () {
//             showDialog(
//               context: context,
//               builder: (BuildContext context) {
//                 return const SignupPopupWidget(); // LoginPage 위젯을 반환합니다.
//               },
//             );
//           },
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:arbo_frontend/widgets/login_widgets/signup_popup_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginPopupWidget extends StatefulWidget {
  const LoginPopupWidget({super.key});

  @override
  _LoginPopupWidgetState createState() => _LoginPopupWidgetState();
}

class _LoginPopupWidgetState extends State<LoginPopupWidget> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void validate() {
    if (emailController.text.trim() == '' ||
        passwordController.text.trim() == '') {
      return; // 값이 비었다면, 아무것도 수행하지 않음.
    }

    setState(() {
      isLoading = true; // 로딩 애니메이션을 위한 불리언 변수 활성화
    });

    Future.delayed(const Duration(seconds: 2)).then((value) {
      setState(() {
        isLoading = false; // 로딩 종료
        signIn(); // 그리고 signIn() 실행
      });
    });
  }

  void signIn() {
    try {
      showCheck();
      FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim())
          .then((value) => Navigator.of(context).pop());
    } catch (e) {
      debugPrint('에러: $e');
    }
  }

  void showCheck() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Center(
        child: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 100.0,
        ).animate().scale(duration: 300.ms).then(delay: 500.ms).scale(
              duration: 300.ms,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('로그인'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'example@example.com',
              ),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child:
              isLoading ? const CircularProgressIndicator() : const Text('로그인'),
          onPressed: () {
            if (!isLoading) {
              validate();
            }
          },
        ),
        TextButton(
          child: const Text('회원가입'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const SignupPopupWidget(); // SignupPopupWidget을 반환합니다.
              },
            );
          },
        ),
      ],
    );
  }
}
