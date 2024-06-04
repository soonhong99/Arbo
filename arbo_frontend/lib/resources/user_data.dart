import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String nickname = 'null'; // To store the nickname of the user

User? currentLoginUser;

DocumentSnapshot? loginUserData;

DocumentSnapshot? dataWithPostIdSnapshot;
List<DocumentSnapshot> commentsSnapshotDocs = [];
Map<String, List<Map<String, dynamic>>> commentstoMap = {};

// post id, 클릭했다면 true, 아니면 false
Map<String, bool> postClickHeart = {};
