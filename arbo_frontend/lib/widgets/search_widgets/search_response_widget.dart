import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';

class Product {
  final String postId;
  final String title;
  final String image;

  Product(this.postId, this.title, this.image);

  static Product fromJson(Map<String, dynamic> json) {
    return Product(
      json['objectID'] ?? 'Unknown Id',
      json['title'] ?? 'Unknown title',
      (json['designedPicture'] != null && json['designedPicture'].isNotEmpty)
          ? json['designedPicture'][0]
          : 'https://via.placeholder.com/150', // Default placeholder image URL
    );
  }
}

class HitsPage {
  const HitsPage(this.items, this.pageKey, this.nextPageKey);

  final List<Product> items;
  final int pageKey;
  final int? nextPageKey;

  factory HitsPage.fromResponse(SearchResponse response) {
    final items = response.hits.map<Product>(Product.fromJson).toList();
    final isLastPage = response.page >= response.nbPages;
    final nextPageKey = isLastPage ? null : response.page + 1;
    return HitsPage(items, response.page, nextPageKey);
  }
}

class SearchMetadata {
  final int nbHits;

  const SearchMetadata(this.nbHits);

  factory SearchMetadata.fromResponse(SearchResponse response) =>
      SearchMetadata(response.nbHits);
}
