import 'package:arbo_frontend/data/prompt_history.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

class PostCreationHelper {
  final ChatHistory chatHistory;
  final GenerativeModel vertexAIModel;

  PostCreationHelper({required this.chatHistory, required this.vertexAIModel});

  Future<Map<String, String>> getSuggestions() async {
    final conversation = chatHistory.getFullConversation();
    List<Part> parts = [
      TextPart(
          '''You are the person in charge of writing down your local issue board so that you can start with a personal issue and progressively participate in a larger local issue. 
          \nYou should be able to imply in the title what user want specifically based on what the user has said.
          \nPlease give the subject and title of the local issue regarding the content in one sentence appropriately.
          \nSentences must not be too long.
          \nTopic is limited to the following seven.
          \n1. Education and Development 
          \n2. Improving Facilities 
          \n3. Recycling Management 
          \n5. Crime Prevention 
          \n6. Local Commercial
          \n7. Local Events'''),
      TextPart(
          "Conversations with prompts about the problem: 'user' : \"hi. i'm fighting with my friend.\"\n'model' : \"I'm sorry to hear that you're fighting with your friend.      It can be really tough when you feel like you're drifting apart.      It's happened to me before, and it's hard not to feel upset.      Have you considered talking to them about what's bothering you?      It might help to clear the air and see if you can work things out.\n\"\n'user' : \"no they don't want to listen my voice\"\n'model' : \"I understand how frustrating it can be when someone doesn't want to listen to you.     It feels like they're not taking you seriously, and that can be really hurtful.      Have you tried writing them a letter or sending them a message expressing your feelings?      Sometimes seeing things in writing can help people understand better.      It can also give them space to process their thoughts before replying.\n\""),
      TextPart(
          "topic, title and reason: topic: Education and Youth Development\ntitle:I need a counselor that's easy for the kids to get to\nreason: fight my friend because they hate me no reason"),
      TextPart("Conversations with prompts about the problem: $conversation"),
      TextPart("topic, title and reason: ")
    ];

    const maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await vertexAIModel
            .generateContent([Content("user", parts)]).timeout(
                const Duration(seconds: 30)); // 30초 타임아웃 추가
        final response = result.text;

        if (response == null || response.isEmpty) {
          throw Exception('Response is null or empty');
        }

        final lines = response.split('\n');
        String topic = '';
        String title = '';
        String reason = '';

        for (var line in lines) {
          if (line.toLowerCase().startsWith('topic:')) {
            topic = line.substring(6).trim();
          } else if (line.toLowerCase().startsWith('title:')) {
            title = line.substring(6).trim();
          } else if (line.toLowerCase().startsWith('reason:')) {
            reason = line.substring(7).trim();
          }
        }

        topic = topic.replaceAll('*', '');
        title = title.replaceAll('*', '');
        reason = reason.replaceAll('*', '');

        if (topic.isEmpty || title.isEmpty || reason.isEmpty) {
          throw Exception(
              'Failed to extract topic or title or reason from response');
        }

        return {'topic': topic, 'title': title, 'reason': reason};
      } catch (e) {
        print('Error in getSuggestions (attempt ${attempt + 1}): $e');
        if (attempt == maxRetries - 1) {
          return {
            'topic': 'Error occurred',
            'title': 'Please try again',
            'reason': 'Unable to generate response after $maxRetries attempts'
          };
        }
        await Future.delayed(Duration(seconds: 2 * (attempt + 1))); // 재시도 전 대기
      }
    }

    throw Exception('Failed to get suggestions after $maxRetries attempts');
  }
}
