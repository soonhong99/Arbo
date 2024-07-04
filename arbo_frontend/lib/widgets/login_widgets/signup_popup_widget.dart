// import 'package:firebase_core/firebase_core.dart';
import 'package:arbo_frontend/data/user_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class SignupPopupWidget extends StatefulWidget {
  const SignupPopupWidget({super.key});

  @override
  _SignupPopupWidgetState createState() => _SignupPopupWidgetState();
}

class _SignupPopupWidgetState extends State<SignupPopupWidget> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  List<String> postClickedHeart = [];
  List<String> promptSearchHistory = [];
  bool isLoading = false;
  String? errorMessage;

  String? _country;
  String? _adminArea;
  String? _locality;

  bool showIntro = true;
  bool showLocationConfirmation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // 위치 권한이 거부된 경우 처리
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        setState(() {
          _country = placemark.country;
          _adminArea = placemark.administrativeArea;
          _locality = placemark.locality;
        });
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showIntro) {
      return _buildIntroDialog();
    } else if (showLocationConfirmation) {
      return _buildLocationConfirmationDialog();
    } else {
      return _buildSignupDialog();
    }
  }

  Widget _buildIntroDialog() {
    return AlertDialog(
      title: const Text('앱 소개'),
      content: const Text(
          '이 앱은 local 사회를 우리가 직접 paint를 해서 pain을 없애자! 라는 취지로 만들었습니다.'),
      actions: <Widget>[
        TextButton(
          child: const Text('그렇군요!'),
          onPressed: () {
            setState(() {
              showIntro = false;
              showLocationConfirmation = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationConfirmationDialog() {
    return AlertDialog(
      title: const Text('위치 확인'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('감지된 위치:'),
          Text('국가: $_country'),
          Text('시/도: $_adminArea'),
          Text('군/구: $_locality'),
          const Text('이 정보가 맞습니까?'),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('예'),
          onPressed: () {
            setState(() {
              showLocationConfirmation = false;
            });
          },
        ),
        TextButton(
          child: const Text('아니오'),
          onPressed: () {
            // 수동으로 위치를 입력할 수 있는 다이얼로그를 표시하거나
            // 다시 위치를 감지하는 로직을 구현할 수 있습니다.
          },
        ),
      ],
    );
  }

  Widget _buildSignupDialog() {
    // 기존의 회원가입 다이얼로그 코드
    return AlertDialog(
      title: const Text('회원가입'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('국가: $_country'),
            Text('시/도: $_adminArea'),
            Text('군/구: $_locality'),
            _buildTextField(
                controller: _idController,
                label: '아이디',
                hintText: '한글, 영어, 숫자'),
            _buildTextField(
                controller: _passwordController,
                label: '비밀번호',
                hintText: '한글, 영어, 숫자',
                obscureText: true),
            _buildTextField(
                controller: _birthController,
                label: '생년월일',
                hintText: '숫자만 입력하세요'),
            _buildTextField(
                controller: _nameController, label: '이름', hintText: '한글, 영어'),
            _buildTextField(
                controller: _nicknameController,
                label: '닉네임',
                hintText: '한글, 영어, 숫자'),
            _buildTextField(
                controller: _emailController,
                label: '이메일 주소',
                hintText: '한글, 영어, 숫자, 기호'),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: CircularProgressIndicator(),
              ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: signUp,
          child: const Text('회원가입'),
        ),
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      String? label,
      String? hintText,
      bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
        ),
        obscureText: obscureText,
      ),
    );
  }

  void signUp() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim());

      await firestore_instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        '아이디': _idController.text,
        '생년월일': _birthController.text,
        '이름': _nameController.text,
        '닉네임': _nicknameController.text,
        '이메일 주소': _emailController.text,
        '국가': _country,
        '시/도': _adminArea,
        '군/구': _locality,
        '하트 누른 게시물': [],
        '프롬프트 기록': [],
      });

      setState(() {
        isLoading = false;
      });

      showResisterDialog();
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = '알 수 없는 오류가 발생했습니다. 다시 시도해주세요.';
      });
    }
  }

  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case "user-not-found":
      case "wrong-password":
        return "이메일 혹은 비밀번호가 일치하지 않습니다.";
      case "email-already-in-use":
        return "이미 사용 중인 이메일입니다.";
      case "weak-password":
        return "비밀번호는 6글자 이상이어야 합니다.";
      case "network-request-failed":
        return "네트워크 연결에 실패 하였습니다.";
      case "invalid-email":
        return "잘못된 이메일 형식입니다.";
      case "internal-error":
        return "잘못된 요청입니다.";
      default:
        return "로그인에 실패 하였습니다.";
    }
  }

  void showResisterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원가입 성공'),
        content: const Text('회원가입이 성공적으로 완료되었습니다.'),
        actions: <Widget>[
          TextButton(
            child: const Text('확인'),
            onPressed: () {
              auth.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
