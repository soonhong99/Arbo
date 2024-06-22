// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class SearchResultScreen extends StatelessWidget {
//   final String query;

//   const SearchResultScreen({super.key, required this.query});

//   Future<List<Map<String, dynamic>>> _searchPosts() async {
//     QuerySnapshot titleResults = await FirebaseFirestore.instance
//         .collection('posts')
//         .where('title', isGreaterThanOrEqualTo: query)
//         .where('title', isLessThanOrEqualTo: '$query\uf8ff')
//         .get();

//     QuerySnapshot contentResults = await FirebaseFirestore.instance
//         .collection('posts')
//         .where('content', isGreaterThanOrEqualTo: query)
//         .where('content', isLessThanOrEqualTo: '$query\uf8ff')
//         .get();

//     List<Map<String, dynamic>> posts = [];

//     for (var doc in titleResults.docs) {
//       posts.add(doc.data() as Map<String, dynamic>);
//     }

//     for (var doc in contentResults.docs) {
//       posts.add(doc.data() as Map<String, dynamic>);
//     }

//     return posts;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('검색 결과'),
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _searchPosts(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('죄송합니다 해당 내용의 게시글을 찾지 못했습니다.'));
//           }

//           List<Map<String, dynamic>> posts = snapshot.data!;

//           return ListView.builder(
//             itemCount: posts.length,
//             itemBuilder: (context, index) {
//               Map<String, dynamic> post = posts[index];
//               return ListTile(
//                 title: Text(post['title']),
//                 subtitle: Text(post['content']),
//                 onTap: () {
//                   // Navigate to the post detail screen if needed
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:algolia/algolia.dart';

class SearchResultScreen extends StatelessWidget {
  final String query;

  const SearchResultScreen({super.key, required this.query});

  Future<List<Map<String, dynamic>>> _searchPosts(String query) async {
    const Algolia algolia = Algolia.init(
      applicationId: 'X7K8OF73JC',
      apiKey: '69a1a2b217890e2ae9669e0db3f1beda',
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
