import 'package:arbo_frontend/design/paint_stroke.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_geocoding/google_geocoding.dart';

String nickname = 'null'; // To store the nickname of the user
String userUid = 'null';
int selectedIndex = -1;
List<dynamic> promptSearchHistory = [];
User? currentLoginUser;
bool dataChanged = false;
bool firstSpecificPostTouch = true;
DocumentSnapshot? loginUserData;
final FirebaseAuth auth = FirebaseAuth.instance;

bool first_home_clicked = true;

List<DocumentSnapshot> postListSnapshot = [];
List<dynamic> likedPosts = [];
Map<String, Map<String, dynamic>> allPostDataWithPostId = {};

// post id, 클릭했다면 true, 아니면 false
Map<String, bool> postClickHeart = {};
final firestore_instance = FirebaseFirestore.instance;
final firebase_appcheck_instance = FirebaseAppCheck.instance;

var googleGeocoding = GoogleGeocoding(dotenv.env['GOOGLE_GEOCODING_KEY']!);

String address = 'Cannot find location';

List<PaintStroke> userPaintBackGround = [];

int countTotalComments(List<dynamic>? comments) {
  if (comments == null) {
    return 0;
  } else {
    int count = comments.length;
    for (var comment in comments) {
      count += countTotalComments(comment['replies']);
    }
    return count;
  }
}
