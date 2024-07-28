import 'package:arbo_frontend/widgets/search_widgets/search_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchDesignBar extends StatelessWidget {
  const SearchDesignBar({
    super.key,
    required this.screenWidth,
  });

  final double screenWidth;
  final double formalScreenWidth = 600;

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    void performSearch() {
      String query = controller.text.trim();
      if (query.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SearchResultsPage(query: query),
          ),
        );
      }
    }

    return SizedBox(
      width: screenWidth - 250 < formalScreenWidth
          ? screenWidth - 250
          : formalScreenWidth,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              showCursor: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9a-zA-Zㄱ-ㅎ가-힣\s]'),
                ),
              ],
              decoration: const InputDecoration(
                counterText: '',
                labelText: 'search compain\'ting',
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
    );
  }
}
