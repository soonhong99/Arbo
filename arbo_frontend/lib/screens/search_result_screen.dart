// 현재 안쓰이는 중
import 'package:flutter/material.dart';
import 'package:algolia/algolia.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SearchResultScreen extends StatelessWidget {
  final String query;

  const SearchResultScreen({super.key, required this.query});

  Future<List<Map<String, dynamic>>> _searchPosts(String query) async {
    Algolia algolia = Algolia.init(
      applicationId: dotenv.env['ALGOLIA_APPLICATION_ID']!,
      apiKey: dotenv.env['ALGOLIA_API_KEY']!,
    );

    AlgoliaQuery algoliaQuery = algolia.instance.index('posts').query(query);
    AlgoliaQuerySnapshot snap = await algoliaQuery.getObjects();

    return snap.hits.map((hit) => hit.data).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색 결과'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _searchPosts(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('죄송합니다 해당 내용의 게시글을 찾지 못했습니다.'));
          }

          List<Map<String, dynamic>> posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> post = posts[index];
              return ListTile(
                title: Text(post['title']),
                subtitle: Text(post['content']),
                onTap: () {
                  // Navigate to the post detail screen if needed
                },
              );
            },
          );
        },
      ),
    );
  }
}
