import 'package:arbo_frontend/resources/fetch_data.dart';
import 'package:arbo_frontend/widgets/login_widgets/signup_popup_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPopupWidget extends StatefulWidget {
  // 로그인에 성공하면 해야할 콜백 함수 - login을 다른 class에서 했을 때 사용
  final Function(User) onLoginSuccess;

  const LoginPopupWidget({super.key, required this.onLoginSuccess});

  @override
  _LoginPopupWidgetState createState() => _LoginPopupWidgetState();
}

class _LoginPopupWidgetState extends State<LoginPopupWidget> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isLoginSuccessful = false;
  String errorMessage = '';

  void validate() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = '이메일과 비밀번호를 입력하세요.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    signIn();
  }

  void signIn() async {
    FetchData fetchData = FetchData();

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      setState(() {
        isLoginSuccessful = true;
        isLoading = false;
      });
      // 로그인된 회원 정보 fetch 장소
      fetchData.fetchLoginUserData(userCredential.user!);

      widget.onLoginSuccess(userCredential.user!);

      Future.delayed(const Duration(seconds: 2)).then((_) {
        Navigator.of(context).pop();
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = _handleFirebaseAuthError(e.code);
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = '오류: $e';
      });
    }
  }

  String _handleFirebaseAuthError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
      case 'wrong-password':
        return '이메일 혹은 비밀번호가 일치하지 않습니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호는 6글자 이상이어야 합니다.';
      case 'network-request-failed':
        return '네트워크 연결에 실패 하였습니다.';
      case 'invalid-email':
        return '잘못된 이메일 형식입니다.';
      case 'internal-error':
        return '잘못된 요청입니다.';
      default:
        return '로그인에 실패 하였습니다.';
    }
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
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (isLoginSuccessful)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: AnimatedOpacity(
                  opacity: isLoginSuccessful ? 1.0 : 0.0,
                  duration: const Duration(seconds: 1),
                  child: const Text(
                    '로그인 성공!',
                    style: TextStyle(color: Colors.green),
                  ),
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
            // Handle sign up navigation
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
