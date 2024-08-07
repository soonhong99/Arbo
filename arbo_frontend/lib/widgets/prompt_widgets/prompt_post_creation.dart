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
          '''You are the person in charge of creating local issue boards so that you can gradually engage your personal issues in the local community.
          \nYou should be able to imply in the title what user want specifically based on what the user has said.
          \nPlease give the subject and title of the local issue regarding the content in one sentence appropriately.
          \nSentences must not be too long.
          \nFor example, if the user says they don't know how to date, suggest a title like 'I need a mentor to teach me about dating!' Or if they write about the weather being too hot, create a title like 'Can someone make something to cool me down?' Give me titles like these.
          \nTopic is limited to the following seven.
          \n1. Education and Development 
          \n2. Improving Facilities 
          \n3. Recycling Management 
          \n5. Crime Prevention 
          \n6. Local Commercial
          \n7. Local Events'''),
      TextPart(
          "Conversations with prompts about the problem: 'user' : \"hi. i'm fighting with my friend.\"\n'model' : \"I'm really sorry to hear you're fighting with your friend. It's a tough situation that can leave you feeling hurt and confused. It's completely normal to feel upset. Sometimes, taking a step back to reflect on the situation can help. Have you thought about what might have led to this conflict? Understanding the root cause could be a good first step towards resolving it.\"\n'user' : \"no they don't want to listen my voice\"\n'model' : \"That must be incredibly frustrating and hurtful. Feeling unheard by someone you care about is a painful experience. Your feelings are absolutely valid. In situations like this, it might help to consider alternative ways of communicating. Perhaps writing down your thoughts could help organize your feelings. You could then decide whether to share this with your friend when things calm down. Remember, it's okay to take some time for yourself to process your emotions. Your well-being is important too.\""),
      TextPart(
          "topic, title and reason: topic: Education and Youth Development\ntitle:I need counselors who can smooth out our relationships with our friends.\nreason: fight my friend because they hate me no reason"),
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
