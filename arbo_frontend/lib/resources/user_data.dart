import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String nickname = 'null'; // To store the nickname of the user
String userUid = 'null';
User? currentLoginUser;
bool dataChanged = false;
bool firstSpecificPostTouch = true;
DocumentSnapshot? loginUserData;
final FirebaseAuth auth = FirebaseAuth.instance;

List<DocumentSnapshot> postListSnapshot = [];
List<dynamic> likedPosts = [];
Map<String, Map<String, dynamic>> allPostDataWithPostId = {};

// post id, 클릭했다면 true, 아니면 false
Map<String, bool> postClickHeart = {};
