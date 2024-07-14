import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/widgets/main_widgets/custom_toast_widget.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_geocoding/google_geocoding.dart';
import 'package:intl/intl.dart';

class SignupPopupWidget extends StatefulWidget {
  const SignupPopupWidget({super.key});

  @override
  _SignupPopupWidgetState createState() => _SignupPopupWidgetState();
}

class _SignupPopupWidgetState extends State<SignupPopupWidget> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _verifyPasswordController =
      TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController1 = TextEditingController();
  final TextEditingController _phoneNumberController2 = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  FocusNode passwordFocusNode = FocusNode();
  FocusNode verifyPasswordFocusNode = FocusNode();
  FocusNode phoneNumberFocusNode1 = FocusNode();
  FocusNode phoneNumberFocusNode2 = FocusNode();
  FocusNode otpFocusNode = FocusNode();

  bool authOk = false;
  bool passwordHide = true;
  bool requestedAuth = false;

  String? verificationId;
  bool showLoading = false;
  bool showLocationConfirmation = false;
  bool showIntro = true;
  bool isLoadingLocation = false;
  String? errorMessage;
  String? myCountry;
  String? myCity;
  String? myDistrict;
  String _selectedCountryCode = '+82'; // 기본값으로 한국 국가 코드 설정

  String? _passwordError;
  bool _isPasswordValid = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (isLocationSet()) {
      setState(() {
        showLocationConfirmation = true;
      });
      return;
    } else {
      try {
        LocationPermission permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // 위치 권한이 거부된 경우 처리
          setState(() {
            isLoadingLocation = false;
            errorMessage = '위치 권한이 거부되었습니다.';
          });
          return;
        }

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
                List<String> addressComponents = address.split(' ');
                if (addressComponents.length >= 3) {
                  myCountry = addressComponents[0];
                  myCity = addressComponents[1];
                  myDistrict = addressComponents[2];

                  locationMessage = '$myCountry, $myCity, $myDistrict';
                }
              },
            );
          } else {
            errorMessage = '지명 정보를 가져오지 못했습니다.';
          }
        }
      } catch (e) {
        errorMessage = "위치 정보를 가져오는 중 오류가 발생했습니다: $e";
      } finally {
        setState(() {
          isLoadingLocation = false;
          showLocationConfirmation = true;
        });
      }
    }
  }

  Widget _buildIntroDialog() {
    return AlertDialog(
      title: const Text('위치 정보 동의'),
      content: const Text('당신의 community를 찾기위해서 위치 정보를 허용해주셔야 돼요!'),
      actions: <Widget>[
        TextButton(
          child: const Text('I agreed It!'),
          onPressed: () {
            setState(() {
              showIntro = false;
              //showLocationConfirmation = true;
            });
            _getCurrentLocation();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showIntro && !isLocationSet()) {
      return _buildIntroDialog();
    } else if (showLocationConfirmation) {
      return _buildLocationConfirmationDialog();
    } else {
      return _buildSignupDialog();
    }
  }

  Widget _buildLocationConfirmationDialog() {
    return AlertDialog(
      title: const Text('위치 확인'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('감지된 위치:'),
          Text('Country: $myCountry'),
          Text('City: $myCity'),
          Text('District: $myDistrict'),
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
      ],
    );
  }

  Widget _buildSignupDialog() {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('위치: $myCountry, $myCity, $myDistrict'),
            const SizedBox(height: 20),
            _buildTextField(controller: _idController, label: '아이디'),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력해주세요';
                }
                if (value.length < 6) {
                  return '비밀번호는 6자 이상이어야 합니다';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _isPasswordValid = _verifyPasswordController.text == value;
                  _passwordError = _isPasswordValid ? null : '비밀번호가 일치하지 않습니다';
                });
              },
            ),
            TextFormField(
              controller: _verifyPasswordController,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
                errorText: _passwordError,
                errorStyle: TextStyle(
                    color: _isPasswordValid ? Colors.green : Colors.red),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 다시 입력해주세요';
                }
                if (value != _passwordController.text) {
                  return '비밀번호가 일치하지 않습니다';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _isPasswordValid = _passwordController.text == value;
                  _passwordError =
                      _isPasswordValid ? '올바른 비밀번호!' : '비밀번호가 일치하지 않습니다';
                });
              },
            ),
            TextFormField(
              controller: _birthController,
              decoration: const InputDecoration(labelText: '생년월일 (YYYYMMDD)'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '생년월일을 입력해주세요';
                }
                if (!RegExp(r'^\d{8}$').hasMatch(value)) {
                  return '올바른 형식이 아닙니다 (YYYYMMDD)';
                }
                try {
                  final date = DateFormat('yyyyMMdd').parseStrict(value);
                  if (date.isAfter(DateTime.now())) {
                    return '올바르지 않은 날짜입니다';
                  }
                } catch (e) {
                  return '올바르지 않은 날짜입니다';
                }
                return null;
              },
            ),
            _buildTextField(controller: _nameController, label: '이름'),
            _buildTextField(controller: _nicknameController, label: '닉네임'),
            _buildTextField(controller: _emailController, label: '이메일 주소'),
            const SizedBox(height: 20),
            _buildPhoneNumberInput(),
            const SizedBox(height: 10),
            if (requestedAuth) _buildOtpInput(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: authOk ? signUp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: const Text('가입하기'),
            ),
            if (showLoading) const Center(child: CircularProgressIndicator()),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberInput() {
    return Row(
      children: [
        CountryCodePicker(
          onChanged: _onCountryChange,
          initialSelection: 'KR',
          favorite: const ['+82', 'KR'],
          showCountryOnly: false,
          showOnlyCountryWhenClosed: false,
          alignLeft: false,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _phoneNumberController1,
            focusNode: phoneNumberFocusNode1,
            decoration: const InputDecoration(
              labelText: '앞 4자리',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 4,
            onChanged: (value) {
              if (value.length == 4) {
                FocusScope.of(context).requestFocus(phoneNumberFocusNode2);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _phoneNumberController2,
            focusNode: phoneNumberFocusNode2,
            decoration: const InputDecoration(
              labelText: '뒤 4자리',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 4,
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: authOk ? null : _requestPhoneAuth,
          child: Text(authOk ? '인증완료' : '인증요청'),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _otpController,
            focusNode: otpFocusNode,
            decoration: const InputDecoration(
              labelText: '인증번호',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _verifyOtp,
          child: const Text('확인'),
        ),
      ],
    );
  }

  void _onCountryChange(CountryCode countryCode) {
    setState(() {
      _selectedCountryCode = countryCode.dialCode ?? '+82';
    });
    print("New Country selected: $countryCode");
  }

  void _requestPhoneAuth() async {
    setState(() {
      showLoading = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber:
          "${_selectedCountryCode}10${_phoneNumberController1.text}${_phoneNumberController2.text}",
      verificationCompleted: (phoneAuthCredential) async {
        // 자동 인증 완료 (안드로이드에서만 작동)
        signInWithPhoneAuthCredential(phoneAuthCredential);
      },
      verificationFailed: (verificationFailed) async {
        setState(() {
          showLoading = false;
          errorMessage = "인증 코드 발송 실패: ${verificationFailed.message}";
        });
      },
      codeSent: (verificationId, resendingToken) async {
        setState(() {
          showLoading = false;
          this.verificationId = verificationId;
          requestedAuth = true;
        });
        CustomToast.show(context, "인증 코드가 발송되었습니다.");
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  void _verifyOtp() {
    PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
      verificationId: verificationId!,
      smsCode: _otpController.text,
    );
    signInWithPhoneAuthCredential(phoneAuthCredential);
  }

  void signInWithPhoneAuthCredential(
      PhoneAuthCredential phoneAuthCredential) async {
    setState(() {
      showLoading = true;
    });

    try {
      final authCredential =
          await _auth.signInWithCredential(phoneAuthCredential);

      if (authCredential.user != null) {
        setState(() {
          authOk = true;
          requestedAuth = false;
          showLoading = false;
        });

        await _auth.currentUser?.delete();
        await _auth.signOut();
        CustomToast.show(context, "전화번호 인증이 완료되었습니다.");
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        showLoading = false;
        errorMessage = "인증 실패: ${e.message}";
      });
    }
  }

  void signUp() async {
    if (_passwordController.text != _verifyPasswordController.text) {
      setState(() {
        errorMessage = "비밀번호가 일치하지 않습니다.";
      });
      return;
    }

    setState(() {
      showLoading = true;
      errorMessage = null;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        '아이디': _idController.text,
        '생년월일': _birthController.text,
        '이름': _nameController.text,
        '닉네임': _nicknameController.text,
        '이메일 주소': _emailController.text,
        'country': myCountry,
        'city': myCity,
        'district': myDistrict,
        '전화번호':
            "+8210${_phoneNumberController1.text}${_phoneNumberController2.text}",
        '하트 누른 게시물': [],
        '프롬프트 기록': [],
        'alertMap': {
          'alertComment': [],
          'alertHeart': [],
        },
      });

      setState(() {
        showLoading = false;
      });
      CustomToast.show(context, "회원가입이 완료되었습니다.");

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
        showLoading = false;
        errorMessage = getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        showLoading = false;
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
}
