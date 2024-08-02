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
  String? _idErrorMessage =
      'Please enter at least 6 characters in English and numbers';
  String? _nicknameErrorMessage =
      'Please enter at least 4 characters, English and numbers';

  final String _phoneErrorMessage = 'Please write down your phone number';
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
        _birthErrorMessage = 'Please enter your date of birth';
        _isBirthValid = false;
      } else if (!RegExp(r'^\d{8}$').hasMatch(birth)) {
        _birthErrorMessage = 'It\'s not the right format (YYYYMMDD)';
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
            _birthErrorMessage = 'Invalid date (future date)';
            _isBirthValid = false;
          } else {
            _birthErrorMessage =
                'You have to enter the exact date of birth to use it, but there is no inconvenience!';
            _isBirthValid = true;
          }
        } catch (e) {
          print('birth error: $e');
          _birthErrorMessage = 'Invalid date';
          _isBirthValid = false;
        }
      }
    });
  }

  void _validateName() {
    final String name = _nameController.text;
    setState(() {
      if (name.isEmpty) {
        _nameErrorMessage = 'Please enter your name';
        _isNameValid = false;
      } else if (!RegExp(r'^[a-zA-Z]+$').hasMatch(name)) {
        _nameErrorMessage =
            'It\'s not the right format (only English, not white space)';
        _isNameValid = false;
      } else {
        _nameErrorMessage =
            'There is no inconvenience in using it only when you enter the exact name!';
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
            errorMessage = 'Location permission denied.';
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
                  //myDistrict = addressComponents[2];

                  locationMessage = '$myCountry, $myCity';
                }
              },
            );
          } else {
            errorMessage = 'Failed to get place name information.';
          }
        }
      } catch (e) {
        errorMessage = "Error getting location information: $e";
      } finally {
        setState(() {
          isLoadingLocation = false;
          showLocationConfirmation = true;
        });
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    return permission != LocationPermission.deniedForever;
  }

  Widget _buildIntroDialog() {
    return AlertDialog(
      title: const Text('Agree Location Information'),
      content: const Text(
          'You have to allow location information to find your community!'),
      actions: <Widget>[
        TextButton(
          child: const Text('I agreed It!'),
          onPressed: () async {
            bool hasPermission = await _checkLocationPermission();
            if (hasPermission) {
              setState(() {
                showIntro = false;
              });
              _getCurrentLocation();
            } else {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Deny Location Permissions'),
                    content: const Text(
                        'You did not agree to the location permissions! Location information is required.'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Try Again'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _buildIntroDialog();
                        },
                      ),
                    ],
                  );
                },
              );
            }
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
      title: const Text('Check Your Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Detected locations:'),
          Text('Country: $myCountry'),
          Text('City: $myCity'),
          const Text('Is this information correct?'),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: isLocationSet()
              ? () {
                  setState(() {
                    showLocationConfirmation = false;
                  });
                }
              : null,
          child: const Text('Yes'), // 위치 정보가 유효하지 않으면 버튼 비활성화
        ),
        TextButton(
          child: const Text('Try Again'),
          onPressed: () {
            setState(() {
              showLocationConfirmation = false;
            });
            _getCurrentLocation();
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
        appBar: AppBar(title: const Text('Create Account')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Location: $myCountry, $myCity'),
              const SizedBox(height: 20),
              _buildTextField(
                  controller: _idController, label: 'Your Own Id', isId: true),
              TextFormField(
                controller: _passwordController,
                decoration:
                    const InputDecoration(labelText: 'Your Own Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _isPasswordValid = _verifyPasswordController.text == value;
                    _passwordError =
                        _isPasswordValid ? null : 'Password doesn\'t match';
                  });
                },
              ),
              TextFormField(
                controller: _verifyPasswordController,
                decoration: InputDecoration(
                  labelText: 'Check the password',
                  errorText: _passwordError,
                  errorStyle: TextStyle(
                      color: _isPasswordValid ? Colors.green : Colors.red),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please Reenter Your Own Password';
                  }
                  if (value != _passwordController.text) {
                    return 'Password doesn\'t match';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _isPasswordValid = _passwordController.text == value;
                    _passwordError = _isPasswordValid
                        ? 'Correct Password!'
                        : 'Password doesn\'t match';
                  });
                },
              ),
              TextFormField(
                controller: _birthController,
                decoration: InputDecoration(
                  labelText: 'Date Of Birth (YYYYMMDD)',
                  errorText: _birthErrorMessage,
                  errorStyle: TextStyle(
                      color: _isBirthValid ? Colors.green : Colors.red),
                ),
                onChanged: (_) => _validateBirth(),
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Type your name in English',
                  errorText: _nameErrorMessage,
                  errorStyle: TextStyle(
                      color: _isNameValid ? Colors.green : Colors.red),
                ),
                onChanged: (_) => _validateName(),
              ),
              _buildTextField(
                  controller: _nicknameController,
                  label: 'Your Own Nickname',
                  isNickname: true),
              _buildTextField(
                  controller: _emailController,
                  label: 'Your Email Address',
                  isEmail: true),
              const SizedBox(height: 20),
              _buildPhoneNumberInput(),
              const SizedBox(height: 10),
              if (requestedAuth) _buildOtpInput(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: authOk ? signUp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: authOk ? Colors.lightGreen : Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
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
          const SizedBox(width: 10),
          if (isId)
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isIdValid ? () => _checkIdDuplicate('id') : null,
                  child: const Text('Check Redundancy'),
                ),
              ],
            )
          else if (isNickname)
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isNicknameValid
                      ? () => _checkIdDuplicate('nickname')
                      : null,
                  child: const Text('Check Redundancy'),
                ),
              ],
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
                              CustomToast.show(context,
                                  "Please authenticate your email again in 30 seconds!");
                            }
                          : _checkEmailAndSendVerification,
                  child: Text(_isEmailSent
                      ? 'Retransmission'
                      : 'Sent Email to Authentication'),
                ),
                if (_isEmailSent && !_isEmailVerified)
                  ElevatedButton(
                    onPressed: _verifyEmail,
                    child: const Text('Authentication completed'),
                  ),
                if (_isEmailVerified)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text('E-mail authentication completed!',
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
      _idErrorMessage =
          'Please enter at least 6 characters in English and numbers';
    } else if (nicknameOrId == 'nickname') {
      controllerText = _nicknameController.text;
      _nicknameErrorMessage =
          'Please enter at least 6 characters in English and numbers';
    }

    final QuerySnapshot result = await _firestore
        .collection('duplicate_id_phonenum')
        .where(nicknameOrId, isEqualTo: controllerText)
        .get();

    setState(() {
      if (result.docs.isEmpty) {
        if (nicknameOrId == 'id') {
          _idErrorMessage = 'This is the ID you can use!';
          _isIdChecked = true;
        } else {
          _nicknameErrorMessage = 'This is a nickname you can use!';
          _isNicknameChecked = true;
        }
      } else {
        if (nicknameOrId == 'id') {
          _idErrorMessage = 'The ID is already in use.';
          _isIdChecked = false;
        } else {
          _nicknameErrorMessage = 'Nicknames already in use.';
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
                      CustomToast.show(context,
                          "Request authentication for your phone number again in 30 seconds!");
                    }
                  : _requestPhoneAuth,
          child: Text(authOk
              ? 'Authentication completed'
              : 'Sent Message for Authentication'),
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
              labelText: 'Authentication Phone Number',
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
          child: const Text('Check'),
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
        errorMessage =
            "Request authentication for your phone number again in 30 seconds!";
      });
      return;
    }

    final String phoneNumber =
        "$_selectedCountryCode${_phoneNumberController.text}";

    // 전화번호 중복 체크
    final QuerySnapshot result = await _firestore
        .collection('duplicate_id_phonenum')
        .where('phoneNum', isEqualTo: phoneNumber)
        .get();

    if (result.docs.isNotEmpty) {
      setState(() {
        errorMessage =
            'This phone number is already in use. Please use a different phone number.';
      });
      return;
    }

    setState(() {
      showLoading = true;
      errorMessage = null;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (phoneAuthCredential) async {
        signInWithPhoneAuthCredential(phoneAuthCredential);
      },
      verificationFailed: (verificationFailed) async {
        setState(() {
          showLoading = false;
          errorMessage =
              "Failed to send authentication code: ${verificationFailed.message}";
        });
      },
      codeSent: (verificationId, resendingToken) async {
        setState(() {
          showLoading = false;
          this.verificationId = verificationId;
          requestedAuth = true;
          _lastPhoneVerificationTime = DateTime.now();
        });
        CustomToast.show(context, "The authentication code has been sent.");
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
        CustomToast.show(context, "Phone number authentication completed.");
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        showLoading = false;
        errorMessage = "Authentication failed: ${e.message}";
      });
    }
  }

  Future<void> _checkEmailAndSendVerification() async {
    if (_lastEmailVerificationTime != null &&
        DateTime.now().difference(_lastEmailVerificationTime!) <
            const Duration(seconds: 30)) {
      setState(() {
        errorMessage = "Please authenticate your email again in 30 seconds!";
      });
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        errorMessage = "Please enter your email.";
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
        errorMessage =
            "This email is already in use, please use another email.";
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
        errorMessage =
            "A certification email has been sent, please check your email.";
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
          errorMessage = "Email authentication is complete!";
        });

        // 임시 사용자 삭제
        if (_tempUserId != null) {
          await _auth.currentUser?.delete();
          await _auth.signOut();
          _tempUserId = null;
        }
      } else {
        setState(() {
          errorMessage =
              "Your email has not been authenticated yet, please check your email.";
        });
      }
    }
  }

  void signUp() async {
    if (!_isIdChecked) {
      setState(() {
        errorMessage = "Please double-check your ID.";
      });
      return;
    }

    if (!_isNicknameChecked) {
      setState(() {
        errorMessage = "Please double-check the nicknames.";
      });
      return;
    }

    if (!_isEmailVerified) {
      setState(() {
        errorMessage = "Please complete the email authentication.";
      });
      return;
    }

    if (!_isBirthValid) {
      setState(() {
        errorMessage = "Please enter a valid date of birth.";
      });
      return;
    }

    if (_passwordController.text != _verifyPasswordController.text) {
      setState(() {
        errorMessage = "Password does not match.";
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
        'email': _emailController.text.trim(),
      });

      setState(() {
        showLoading = false;
      });
      CustomToast.show(context, "You have completed your membership.");

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
        showLoading = false;
        errorMessage = getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        showLoading = false;
        errorMessage = 'An unknown error occurred, please try again.';
      });
    }
  }

  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case "user-not-found":
      case "wrong-password":
        return "Email or password does not match.";
      case "email-already-in-use":
        return "This email is already in use.";
      case "weak-password":
        return "Password must be at least 6 characters long.";
      case "network-request-failed":
        return "Network connection failed.";
      case "invalid-email":
        return "Invalid email format.";
      case "internal-error":
        return "Invalid request.";
      default:
        return "Login failed.";
    }
  }
}
