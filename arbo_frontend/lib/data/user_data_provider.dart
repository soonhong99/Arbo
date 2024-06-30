import 'package:arbo_frontend/data/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = firestore_instance;

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
      'designedPicture': allDataSnapshot['designedPicture'],
      'visitedUser': allDataSnapshot['visitedUser'],
    };
  }

  Future<void> fetchLoginUserData(User? user) async {
    if (user == null) {
      currentLoginUser = null;
      notifyListeners();
      return;
    }
    // print(user);
    DocumentSnapshot userDoc =
        await firestore_instance.collection('users').doc(user.uid).get();
    loginUserData = userDoc;
    nickname = loginUserData!['닉네임'];

    notifyListeners();
  }

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
