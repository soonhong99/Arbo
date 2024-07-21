import 'dart:async';

import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/widgets/main_widgets/custom_toast_widget.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_geocoding/google_geocoding.dart';

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
  final TextEditingController _phoneNumberController = TextEditingController();
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
  String _selectedCountryCode = '+82'; // 기본값으로 한국 국가 코드 설정
  bool _isIdChecked = false;
  bool _isNicknameChecked = false;
  String? _idErrorMessage = '6자 이상, 영어 및 숫자로 입력해주세요';
  String? _nicknameErrorMessage = '4자 이상, 영어 및 숫자로 입력해주세요';

  String? _phoneErrorMessage = '본인 핸드폰 번호를 써주세요';
  String? _passwordError;

  bool _isPasswordValid = false;
  bool _isIdValid = false;
  bool _isNicknameValid = false;

  bool _isEmailVerified = false;
  bool _isEmailSent = false;
  String? _tempUserId;

  String? _birthErrorMessage;
  bool _isBirthValid = false;

  String? _nameErrorMessage;
  bool _isNameValid = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _lastEmailVerificationTime;
  DateTime? _lastPhoneVerificationTime;

  Timer? _authTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _idController.addListener(_validateId);
    _nicknameController.addListener(_validateNickname);
    _birthController.addListener(_validateBirth);
    _nameController.addListener(_validateName);

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && user.emailVerified) {
        _verifyEmail();
      }
    });
  }

  @override
  void dispose() {
    _idController.removeListener(_validateId);
    _idController.dispose();
    _nicknameController.removeListener(_validateNickname);
    _nicknameController.dispose();
    _birthController.removeListener(_validateBirth);
    _birthController.dispose();
    _nameController.removeListener(_validateName);
    _nameController.dispose();
    // ... 다른 controller들의 dispose ...
    _authTimer?.cancel();

    super.dispose();
  }

  void _validateId() {
    final String id = _idController.text;
    setState(() {
      _isIdValid = id.length >= 6 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(id);
    });
  }

  void _validateNickname() {
    final String nickname = _nicknameController.text;
    setState(() {
      _isNicknameValid =
          nickname.length >= 4 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(nickname);
    });
  }

  void _validateBirth() {
    final String birth = _birthController.text;
    setState(() {
      if (birth.isEmpty) {
        _birthErrorMessage = '생년월일을 입력해주세요';
        _isBirthValid = false;
      } else if (!RegExp(r'^\d{8}$').hasMatch(birth)) {
        _birthErrorMessage = '올바른 형식이 아닙니다 (YYYYMMDD)';
        _isBirthValid = false;
      } else {
        try {
          final year = int.parse(birth.substring(0, 4));
          final month = int.parse(birth.substring(4, 6));
          final day = int.parse(birth.substring(6, 8));

          // 월과 일이 유효한지 확인
          if (month < 1 || month > 12 || day < 1 || day > 31) {
            throw const FormatException('Invalid month or day');
          }

          final date = DateTime(year, month, day);

          // 날짜가 유효한지 확인
          if (date.month != month || date.day != day) {
            throw const FormatException('Invalid date');
          }

          if (date.isAfter(DateTime.now())) {
            _birthErrorMessage = '올바르지 않은 날짜입니다 (미래 날짜)';
            _isBirthValid = false;
          } else {
            _birthErrorMessage = '정확한 생년월일을 입력해야 불편함이 없답니다!';
            _isBirthValid = true;
          }
        } catch (e) {
          print('birth error: $e');
          _birthErrorMessage = '올바르지 않은 날짜입니다';
          _isBirthValid = false;
        }
      }
    });
  }

  void _validateName() {
    final String name = _nameController.text;
    setState(() {
      if (name.isEmpty) {
        _nameErrorMessage = '이름을 입력해주세요';
        _isNameValid = false;
      } else if (!RegExp(r'^[a-zA-Z]+$').hasMatch(name)) {
        _nameErrorMessage = '올바른 형식이 아닙니다 (only English)';
        _isNameValid = false;
      } else {
        _nameErrorMessage = '정확한 이름을 입력해야 불편함이 없답니다!';
        _isNameValid = true;
      }
    });
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
            address = geocodingResponse[1].formattedAddress!;
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
    return WillPopScope(
      onWillPop: () async {
        if (_tempUserId != null) {
          await _deleteUnverifiedUser();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('회원가입')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('위치: $myCountry, $myCity, $myDistrict'),
              const SizedBox(height: 20),
              _buildTextField(
                  controller: _idController, label: '아이디', isId: true),
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
                    _passwordError =
                        _isPasswordValid ? null : '비밀번호가 일치하지 않습니다';
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
                decoration: InputDecoration(
                  labelText: '생년월일 (YYYYMMDD)',
                  errorText: _birthErrorMessage,
                  errorStyle: TextStyle(
                      color: _isBirthValid ? Colors.green : Colors.red),
                ),
                onChanged: (_) => _validateBirth(),
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '영어로 이름 입력',
                  errorText: _nameErrorMessage,
                  errorStyle: TextStyle(
                      color: _isNameValid ? Colors.green : Colors.red),
                ),
                onChanged: (_) => _validateName(),
              ),
              _buildTextField(
                  controller: _nicknameController,
                  label: '닉네임',
                  isNickname: true),
              _buildTextField(
                  controller: _emailController, label: '이메일 주소', isEmail: true),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    bool isId = false,
    bool isNickname = false,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: isPassword,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                errorText: isId
                    ? _idErrorMessage
                    : (isNickname ? _nicknameErrorMessage : null),
              ),
            ),
          ),
          if (isId)
            ElevatedButton(
              onPressed: _isIdValid ? () => _checkIdDuplicate('id') : null,
              child: const Text('중복확인'),
            )
          else if (isNickname)
            ElevatedButton(
              onPressed:
                  _isNicknameValid ? () => _checkIdDuplicate('nickname') : null,
              child: const Text('중복확인'),
            )
          else if (isEmail)
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isEmailVerified
                      ? null
                      : (_lastEmailVerificationTime != null &&
                              DateTime.now()
                                      .difference(_lastEmailVerificationTime!) <
                                  const Duration(seconds: 30))
                          ? () {
                              CustomToast.show(
                                  context, "30초 뒤에 다시 이메일을 인증해주세요!");
                            }
                          : _checkEmailAndSendVerification,
                  child: Text(_isEmailSent ? '재전송' : '인증하기'),
                ),
                if (_isEmailSent && !_isEmailVerified)
                  ElevatedButton(
                    onPressed: _verifyEmail,
                    child: const Text('인증 완료'),
                  ),
                if (_isEmailVerified)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text('이메일 인증 완료!',
                        style: TextStyle(color: Colors.green)),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _checkIdDuplicate(String nicknameOrId) async {
    String controllerText = '';
    if (nicknameOrId == 'id') {
      controllerText = _idController.text;
      _idErrorMessage = '6자 이상, 영어 및 숫자로만 입력해주세요';
    } else if (nicknameOrId == 'nickname') {
      controllerText = _nicknameController.text;
      _nicknameErrorMessage = '6자 이상, 영어 및 숫자로만 입력해주세요';
    }

    final QuerySnapshot result = await _firestore
        .collection('duplicate_id_phonenum')
        .where(nicknameOrId, isEqualTo: controllerText)
        .get();

    setState(() {
      if (result.docs.isEmpty) {
        if (nicknameOrId == 'id') {
          _idErrorMessage = '사용할 수 있는 아이디입니다!';
          _isIdChecked = true;
        } else {
          _nicknameErrorMessage = '사용할 수 있는 닉네임입니다!';
          _isNicknameChecked = true;
        }
      } else {
        if (nicknameOrId == 'id') {
          _idErrorMessage = '이미 사용 중인 아이디입니다.';
          _isIdChecked = false;
        } else {
          _nicknameErrorMessage = '이미 사용 중인 닉네임입니다.';
          _isNicknameChecked = false;
        }
      }
    });
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
            controller: _phoneNumberController,
            focusNode: phoneNumberFocusNode1,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: authOk
              ? null
              : (_lastPhoneVerificationTime != null &&
                      DateTime.now().difference(_lastPhoneVerificationTime!) <
                          const Duration(seconds: 30))
                  ? () {
                      CustomToast.show(context, "30초 뒤에 다시 전화번호를 인증요청하세요!");
                    }
                  : _requestPhoneAuth,
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
    if (_lastPhoneVerificationTime != null &&
        DateTime.now().difference(_lastPhoneVerificationTime!) <
            const Duration(seconds: 30)) {
      setState(() {
        errorMessage = "30초 뒤에 다시 전화번호를 인증요청하세요!";
      });
      return;
    }

    final String phoneNumber =
        "$_selectedCountryCode${_phoneNumberController.text}";

    final QuerySnapshot result = await _firestore
        .collection('duplicate_id_phonenum')
        .where('phoneNum', isEqualTo: phoneNumber)
        .get();

    if (result.docs.isNotEmpty) {
      setState(() {
        _phoneErrorMessage = '전에 인증된 전화번호입니다. 다른 전화번호로 인증하세요.';
      });
      return;
    }

    setState(() {
      showLoading = true;
      _phoneErrorMessage = null;
    });
    setState(() {
      showLoading = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
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
          _lastPhoneVerificationTime = DateTime.now();
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

  Future<void> _checkEmailAndSendVerification() async {
    if (_lastEmailVerificationTime != null &&
        DateTime.now().difference(_lastEmailVerificationTime!) <
            const Duration(seconds: 30)) {
      setState(() {
        errorMessage = "30초 뒤에 다시 이메일을 인증해주세요!";
      });
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        errorMessage = "이메일을 입력해주세요.";
      });
      return;
    }

    // 이메일 중복 확인
    final QuerySnapshot result = await _firestore
        .collection('duplicate_id_phonenum')
        .where('email', isEqualTo: email)
        .get();

    if (result.docs.isNotEmpty) {
      setState(() {
        errorMessage = "이미 사용 중인 이메일입니다. 다른 이메일을 사용해주세요.";
      });
      return;
    }

    try {
      // 임시 사용자 생성
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: "temporaryPassword",
      );

      _tempUserId = userCredential.user!.uid;

      // 이메일 인증 링크 발송
      await userCredential.user!.sendEmailVerification();

      // Firestore에 임시 문서 생성
      await _firestore.collection('temp_users').doc(_tempUserId).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 로컬 타이머 설정
      _setAuthTimer();

      setState(() {
        _isEmailSent = true;
        errorMessage = "인증 이메일이 발송되었습니다. 이메일을 확인해주세요.";
        _lastEmailVerificationTime = DateTime.now();
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = getErrorMessage(e.code);
      });
    }
  }

  void _setAuthTimer() {
    _authTimer?.cancel();
    _authTimer = Timer(const Duration(hours: 1), () {
      _deleteUnverifiedUser();
    });
  }

  Future<void> _deleteUnverifiedUser() async {
    if (_tempUserId != null) {
      try {
        await _auth.currentUser?.delete();
        await _firestore.collection('temp_users').doc(_tempUserId).delete();
        _tempUserId = null;
      } catch (e) {
        print("Error deleting unverified user: $e");
      }
    }
  }

  Future<void> _verifyEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      user = FirebaseAuth.instance.currentUser; // Refresh the user object

      if (user!.emailVerified) {
        setState(() {
          _isEmailVerified = true;
          errorMessage = "이메일 인증이 완료되었습니다!";
        });
        // 이메일 정보를 duplicate_id_phonenum에 추가
        await _firestore.collection('duplicate_id_phonenum').add({
          'email': _emailController.text.trim(),
        });

        // 임시 사용자 삭제
        if (_tempUserId != null) {
          await _auth.currentUser?.delete();
          await _auth.signOut();
          _tempUserId = null;
        }
      } else {
        setState(() {
          errorMessage = "이메일이 아직 인증되지 않았습니다. 이메일을 확인해주세요.";
        });
      }
    }
  }

  void signUp() async {
    if (!_isIdChecked) {
      setState(() {
        errorMessage = "아이디 중복 확인을 해주세요.";
      });
      return;
    }

    if (!_isNicknameChecked) {
      setState(() {
        errorMessage = "닉네임 중복 확인을 해주세요.";
      });
      return;
    }

    if (!_isEmailVerified) {
      setState(() {
        errorMessage = "이메일 인증을 완료해주세요.";
      });
      return;
    }

    if (!_isBirthValid) {
      setState(() {
        errorMessage = "올바른 생년월일을 입력해주세요.";
      });
      return;
    }

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

      final String phoneNumber =
          "$_selectedCountryCode${_phoneNumberController.text}";

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        '아이디': _idController.text,
        '생년월일': _birthController.text,
        '이름': _nameController.text,
        '닉네임': _nicknameController.text,
        '이메일 주소': _emailController.text,
        'country': myCountry,
        'city': myCity,
        'district': myDistrict,
        '전화번호': phoneNumber,
        '하트 누른 게시물': [],
        '프롬프트 기록': [],
        'alertMap': {
          'alertComment': [],
          'alertHeart': [],
        },
      });

      await _firestore.collection('duplicate_id_phonenum').add({
        'id': _idController.text,
        'phoneNum': phoneNumber,
        'nickname': _nicknameController.text,
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
