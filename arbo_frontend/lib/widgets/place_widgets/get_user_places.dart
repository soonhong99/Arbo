import 'package:arbo_frontend/data/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> getUserPlaces() async {
  try {
    QuerySnapshot snapshot =
        await firestore_instance.collection('userPlaceInfo').get();
    return snapshot.docs.map((doc) {
      return {
        'country': doc['country'],
        'city': doc['city'],
        'district': doc['district'],
      };
    }).toList();
  } catch (e) {
    print('Error getting places: $e');
    return [];
  }
}
