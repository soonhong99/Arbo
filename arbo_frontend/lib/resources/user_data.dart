import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String nickname = 'null'; // To store the nickname of the user

User? compareUser;

DocumentSnapshot? loginUserData;

DocumentSnapshot? dataWithPostIdSnapshot;
List<DocumentSnapshot> commentsSnapshotDocs = [];
List<Map<String, dynamic>> commentstoMap = [];
