import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/design/paint_stroke.dart';
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

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 15, color: Colors.grey[600]),
        ),
      ],
    );
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
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 2,
              child: Container(
                color: Colors.white,
                height: 140, // 높이를 조금 더 늘림
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.network(item.image, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoItem(Icons.topic, item.topic),
                              _buildInfoItem(Icons.favorite, '${item.hearts}'),
                              _buildInfoItem(
                                  Icons.person, '${item.visitedUser}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 기본 뒤로 가기 버튼 제거
        title: Text('Search Results for "${widget.query}"'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          tooltip: '홈으로 돌아가기',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(children: [
        CustomPaint(
          painter: StrokePainter(userPaintBackGround),
          size: Size.infinite,
        ),
        Column(
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
      ]),
    );
  }
}
