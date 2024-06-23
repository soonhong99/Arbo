import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:arbo_frontend/widgets/search_widgets/search_detail_screen.dart';
import 'package:arbo_frontend/widgets/search_widgets/search_response_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late final HitsSearcher _productsSearcher;
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
      applicationID: dotenv.env['ALGOLIA_APPLICATION_ID']!,
      apiKey: dotenv.env['ALGOLIA_API_KEY']!,
      indexName: dotenv.env['ALGOLIA_INDEX_NAME']!,
    );

    _productsSearcher.applyState(
      (state) => state.copyWith(
        query: widget.query,
        page: 0,
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
    _productsSearcher.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  Widget _hits(BuildContext context) => PagedListView<int, Product>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Product>(
          noItemsFoundIndicatorBuilder: (_) => const Center(
            child: Text('No results found'),
          ),
          itemBuilder: (_, item, __) => GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SearchDetailScreen(postId: item.postId),
                ),
              );
            },
            child: Container(
              color: Colors.white,
              height: 80,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  SizedBox(width: 50, child: Image.network(item.image)),
                  const SizedBox(width: 20),
                  Expanded(child: Text(item.title)),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "${widget.query}"'),
      ),
      body: Column(
        children: [
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
    );
  }
}
