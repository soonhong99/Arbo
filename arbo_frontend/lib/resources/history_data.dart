// previous_data.dart
List<Map<String, dynamic>> pageList = [];

int page_location = 0;

// 눌렀을 때 바로 page location 플러스 되도록 함.
// 만약 아무 히스토리가 없다면 page list에 채워넣고, 바로 전에 방문한 page이면 history에 넣지 않는다.
void addPageToHistory(Map<String, dynamic> pageData) {
  if (pageList.isEmpty) {
    pageList.add(pageData);
  } else if (!_areMapsEqual(pageList[page_location - 1], pageData)) {
    pageList = [];
    pageList.add(pageData);
  }
}

Map<String, dynamic>? getLastVisitedPage() {
  if (pageList.isNotEmpty) {
    return pageList[page_location - 1];
  }
  return null;
}

bool _areMapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
  // 같은 키값을 가지고 있지 않으면 false
  for (String key in map1.keys) {
    if (map2[key] != map1[key]) {
      return false;
    }
  }

  return true;
}
