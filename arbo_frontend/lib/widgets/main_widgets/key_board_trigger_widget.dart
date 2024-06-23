import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class Product {
  final String name;
  final String image;

  Product(this.name, this.image);

  static Product fromJson(Map<String, dynamic> json) {
    return Product(
      json['content'] ?? 'Unknown Name',
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

class KeyBoardTrigger extends StatelessWidget {
  const KeyBoardTrigger({
    super.key,
    required this.screenWidth,
  });

  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => SearchDialog(screenWidth: screenWidth),
        );
      },
    );
  }
}

class SearchDialog extends StatefulWidget {
  const SearchDialog({
    super.key,
    required this.screenWidth,
  });

  final double screenWidth;

  @override
  _SearchDialogState createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late final HitsSearcher _productsSearcher;
  final TextEditingController _searchTextController = TextEditingController();
  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 0);

  Stream<HitsPage> get _searchPage =>
      _productsSearcher.responses.map(HitsPage.fromResponse);

  Stream<SearchMetadata> get _searchMetadata =>
      _productsSearcher.responses.map(SearchMetadata.fromResponse);

  @override
  void initState() {
    super.initState();
    _productsSearcher = HitsSearcher(
      applicationID: 'I0P4IGRC4K',
      apiKey: 'a71066c56d91d321692fda801e2bc0c2',
      indexName: 'posts',
    );

    _searchTextController.addListener(
      () => _productsSearcher.applyState(
        (state) => state.copyWith(
          query: _searchTextController.text,
          page: 0,
        ),
      ),
    );

    _searchPage.listen((page) {
      if (page.pageKey == 0) {
        _pagingController.refresh();
      }
      _pagingController.appendPage(page.items, page.nextPageKey);
    }).onError((error) {
      _pagingController.error = error;
    });
    _pagingController.addPageRequestListener(
      (pageKey) => _productsSearcher.applyState(
        (state) => state.copyWith(
          page: pageKey,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    _productsSearcher.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  void performSearch() {
    String query = _searchTextController.text.trim();
    if (query.isNotEmpty) {
      _productsSearcher.applyState(
        (state) => state.copyWith(
          query: query,
          page: 0,
        ),
      );
    }
  }

  Widget _hits(BuildContext context) => PagedListView<int, Product>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Product>(
          noItemsFoundIndicatorBuilder: (_) => const Center(
            child: Text('No results found'),
          ),
          itemBuilder: (_, item, __) => Container(
            color: Colors.white,
            height: 80,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox(width: 50, child: Image.network(item.image)),
                const SizedBox(width: 20),
                Expanded(child: Text(item.name)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: widget.screenWidth < 600 ? widget.screenWidth - 50 : 600,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchTextController,
                    showCursor: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9a-zA-Zㄱ-ㅎ가-힣\s]'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      counterText: '',
                      labelText: '검색할 게시글을 입력하세요',
                      labelStyle: TextStyle(color: Colors.black26),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(width: 1, color: Colors.black12),
                      ),
                    ),
                    onSubmitted: (value) {
                      performSearch();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: performSearch,
                ),
              ],
            ),
            StreamBuilder<SearchMetadata>(
              stream: _searchMetadata,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('${snapshot.data!.nbHits} hits'),
                );
              },
            ),
            Expanded(
              child: _hits(context),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchMetadata {
  final int nbHits;

  const SearchMetadata(this.nbHits);

  factory SearchMetadata.fromResponse(SearchResponse response) =>
      SearchMetadata(response.nbHits);
}

class SearchResultScreen extends StatelessWidget {
  final String query;

  const SearchResultScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "$query"'),
      ),
      body: Center(
        child: Text('Search results for "$query" will be displayed here.'),
      ),
    );
  }
}
