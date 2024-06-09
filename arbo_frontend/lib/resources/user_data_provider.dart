import 'package:arbo_frontend/resources/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void makeAllDataLocal(DocumentSnapshot allDataSnapshot) {
    allPostDataWithPostId[allDataSnapshot.id] = {
      'postId': allDataSnapshot.id,
      'comments': allDataSnapshot['comments'],
      'content': allDataSnapshot['content'],
      'hearts': allDataSnapshot['hearts'],
      'nickname': allDataSnapshot['nickname'],
      'scale': allDataSnapshot['scale'],
      'timestamp': allDataSnapshot['timestamp'],
      'title': allDataSnapshot['title'],
      'topic': allDataSnapshot['topic'],
      'postOwnerId': allDataSnapshot['userId'],
    };
  }

  Future<void> fetchLoginUserData(User? user) async {
    if (user == null) {
      currentLoginUser = null;
      notifyListeners();
      return;
    }
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    loginUserData = userDoc;
    nickname = loginUserData!['닉네임'];
    notifyListeners();
  }

  // 이걸로 다 이용가능 할듯, comment만 어떻게 collection 분리된거 다시 합쳐서 해야될듯
  Future<void> fetchPostData() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .get();
    postListSnapshot = querySnapshot.docs;
    // 바뀐것을 알리고 싶을 때 - Provider.of<UserDataProvider>(context);
    notifyListeners();
  }
}
