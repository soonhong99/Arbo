import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<String>> extractNounsWithPython(String text) async {
  try {
    final response = await http.post(
      // in debug
      // Uri.parse('http://127.0.0.1:5000/extract_nouns'),
      Uri.parse('https://MeisMeisMe.pythonanywhere.com/extract_nouns'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['nouns']);
    } else {
      throw Exception('Failed to extract nouns');
    }
  } catch (e) {
    print('Error: $e');
    rethrow;
  }
}
