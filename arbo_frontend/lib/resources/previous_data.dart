// previous_data.dart
List<Map<String, dynamic>> previousPageList = [];

int page_location = 0;

void addPageToHistory(Map<String, dynamic> pageData) {
  // 만약 다시 돌아
  if (_areMapsEqual(previousPageList[page_location], pageData)) {
    return;
  }
  if (page_location != previousPageList.length || previousPageList.isEmpty) {
    previousPageList.add(pageData);
    page_location++;
    print(
        'page location: $page_location, page length: ${previousPageList.length}');
  }
}

Map<String, dynamic>? getNextVisitedPage() {
  if (previousPageList.isNotEmpty) {
    return previousPageList[page_location];
  }
  return null;
}

bool _areMapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
  if (map1.length != map2.length) {
    return false;
  }

  for (String key in map1.keys) {
    if (map2[key] != map1[key]) {
      return false;
    }
  }

  return true;
}
