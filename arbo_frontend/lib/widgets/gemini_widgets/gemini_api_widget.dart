import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiApiService {
  final String apiKey;
  final String apiUrl = 'https://api.google.dev/gemini/v1/chat';

  GeminiApiService(this.apiKey);

  Future<Map<String, dynamic>> sendMessage(
      String message, List<Map<String, dynamic>> history) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'history': history,
        'prompt': message,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load response');
    }
  }
}
