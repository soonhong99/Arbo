import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String nickname = 'null'; // To store the nickname of the user

User? currentLoginUser;
bool dataChanged = false;
DocumentSnapshot? loginUserData;
Map<String, bool> isChangedData = {};
DocumentSnapshot? dataWithPostIdSnapshot;
List<DocumentSnapshot> commentsSnapshotDocs = [];
List<DocumentSnapshot> postListSnapshot = [];
Map<String, List<Map<String, dynamic>>> commentstoMap = {};
List<Map<String, dynamic>> commentsWithPostId = [];

// post id, 클릭했다면 true, 아니면 false
Map<String, bool> postClickHeart = {};
