import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserData extends ChangeNotifier {
  User? _user;
  String? _nickname;

  User? get user => _user;
  String? get nickname => _nickname;

  void updateUser(User? newUser) {
    _user = newUser;

    notifyListeners();
  }

  void updateNickname(String? newNickname) {
    _nickname = newNickname;
    notifyListeners();
  }
}
