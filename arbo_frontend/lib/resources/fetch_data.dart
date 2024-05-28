import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Comments 컬렉션의 문서 가져오기
  Future<List<DocumentSnapshot>> fetchCommentsData(String postId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();
    return querySnapshot.docs;
  }

  // 특정 postId에 해당하는 포스트의 정보를 가져오기
  Future<DocumentSnapshot> fetchPostDataById(String postId) async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection('posts').doc(postId).get();
    return documentSnapshot;
  }

  // 특정 postId의 포스트 정보와 해당 포스트의 댓글들을 모두 가져오기
  Future<Map<String, dynamic>> fetchPostAndCommentsData(String postId) async {
    DocumentSnapshot postSnapshot = await fetchPostDataById(postId);
    List<DocumentSnapshot> commentsSnapshot = await fetchCommentsData(postId);
    return {
      'post': postSnapshot,
      'comments': commentsSnapshot,
    };
  }
}
