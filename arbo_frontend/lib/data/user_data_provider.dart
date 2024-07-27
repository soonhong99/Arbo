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
      'status': allDataSnapshot['status'],
      'country': allDataSnapshot['country'],
      'city': allDataSnapshot['city'],
      //'district': allDataSnapshot['district'],
    };
  }

  bool isLoggedIn(User? user) {
    if (user == null) {
      return false;
    } else {
      return true;
    }
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
    myCountry = loginUserData!['country'];
    myCity = loginUserData!['city'];
    //myDistrict = loginUserData!['district'];
    locationMessage = '$myCountry $myCity';
    firstLocationTouch = false;

    notifyListeners();
  }

  Future<void> fetchPostData() async {
    Query query = _firestore.collection('posts');

    // 국가 선택
    if (selectedCountry != 'all') {
      query = query.where('country', isEqualTo: selectedCountry);

      // 도시 선택
      if (selectedCity != 'all') {
        query = query.where('city', isEqualTo: selectedCity);

        // // 지역 선택
        // if (selectedDistrict != 'all') {
        //   query = query.where('district', isEqualTo: selectedDistrict);
        // }
      }
    }

    QuerySnapshot querySnapshot = await query.get();
    postListSnapshot = querySnapshot.docs;
    notifyListeners();
  }
}
