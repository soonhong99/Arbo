import 'package:arbo_frontend/resources/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FetchData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<List<DocumentSnapshot>> fetchPostData() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .get();
    // post에 있는 모든 데이터를 긁어온다.
    return querySnapshot.docs;
  }

  Future<void> fetchLoginUserData(User user) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    loginUserData = userDoc;
  }

  // 특정 postId의 포스트 정보와 해당 포스트의 댓글들을 모두 가져오기
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
    for (var commentSnapshot in commentsSnapshotDocs) {
      Map<String, dynamic> commentData =
          commentSnapshot.data() as Map<String, dynamic>;
      commentstoMap.add(commentData);
    }
    print(commentstoMap.length);
  }
}
