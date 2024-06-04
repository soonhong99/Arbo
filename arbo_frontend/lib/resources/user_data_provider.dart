import 'package:arbo_frontend/resources/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DocumentSnapshot>> fetchPostData() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .get();
    return querySnapshot.docs;
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
    // currentLoginUser = user;
    notifyListeners();
    print('nickname in fetch: $nickname');
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
  }
}
