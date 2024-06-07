import 'package:arbo_frontend/resources/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> fetchPostAndCommentsData(String postId) async {
    DocumentSnapshot withPostIdSnapshot =
        await _firestore.collection('posts').doc(postId).get();
    QuerySnapshot commentSnapshot = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    dataWithPostIdSnapshot = withPostIdSnapshot;
    commentsSnapshotDocs = commentSnapshot.docs;
    commentstoMap[postId] = commentsSnapshotDocs
        .map(
            (commentSnapshot) => commentSnapshot.data() as Map<String, dynamic>)
        .toList();
    notifyListeners();
  }
}
