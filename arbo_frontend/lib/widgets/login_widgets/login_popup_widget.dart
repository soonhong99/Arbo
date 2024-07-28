import 'package:arbo_frontend/data/user_data_provider.dart';
import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/widgets/login_widgets/password_reset_dialog.dart';
import 'package:arbo_frontend/widgets/login_widgets/signup_popup_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPopupWidget extends StatefulWidget {
  // 로그인에 성공하면 해야할 콜백 함수 - login을 다른 class에서 했을 때 사용
  final Function() onLoginSuccess;

  const LoginPopupWidget({super.key, required this.onLoginSuccess});

  @override
  _LoginPopupWidgetState createState() => _LoginPopupWidgetState();
}

class _LoginPopupWidgetState extends State<LoginPopupWidget> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _rememberEmail = false;

  // final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool isLoginSuccessful = false;
  String errorMessage = '';

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('saved_email') ?? '';
      _rememberEmail = prefs.getBool('remember_email') ?? false;
    });
  }

  _saveEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberEmail) {
      await prefs.setString('saved_email', emailController.text);
      await prefs.setBool('remember_email', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('remember_email', false);
    }
  }

  void validate() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email and password.';
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
    // try를 쓰면 해당 안에 들어가있는 변수는 무조건 null이 아니어야 한다. null 이면 catch e로 넘어감.
    try {
      UserCredential? userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      currentLoginUser = userCredential.user;
      if (currentLoginUser != null) {
        userUid = currentLoginUser!.uid;
        setState(() {
          isLoginSuccessful = true;
          isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
        isLoginSuccessful = false;
        errorMessage = _handleFirebaseAuthError(e.code);
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoginSuccessful = false;
        errorMessage = '오류: $e';
      });
    }

    if (isLoginSuccessful == true && mounted) {
      await _saveEmail();
      final userData = Provider.of<UserDataProvider>(context, listen: false);
      userData.fetchLoginUserData(currentLoginUser!);
      Future.delayed(const Duration(milliseconds: 500)).then((_) {
        Navigator.of(context).pop();
        if (currentLoginUser != null) {
          widget.onLoginSuccess();
        }
      });
    }
  }

  String _handleFirebaseAuthError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return '아이디가 일치하지 않습니다.';
      case 'wrong-password':
        return '비밀번호가 일치하지 않습니다.';
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
      title: const Text('Login'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.3, // 화면 너비의 80%로 설정

        child: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Your Email',
                  hintText: 'example@example.com',
                ),
                onSubmitted: (_) => validate(), // Enter 키 처리
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Your Password',
                ),
                onSubmitted: (_) => validate(), // Enter 키 처리
              ),
              Row(
                children: [
                  Checkbox(
                    value: _rememberEmail,
                    onChanged: (bool? value) {
                      setState(() {
                        _rememberEmail = value ?? false;
                      });
                    },
                  ),
                  const Text('Save Your Email'),
                ],
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
                      'Login Success!',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
              onPressed: () {
                if (!isLoading) {
                  validate();
                }
              },
            ),
            TextButton(
              child: const Text('Create Account'),
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
            TextButton(
              child: const Text('Find Your Password'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const PasswordResetDialog();
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
