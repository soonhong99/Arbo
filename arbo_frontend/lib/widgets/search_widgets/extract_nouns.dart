String extractNouns(String text) {
  // 문장을 단어로 분리
  List<String> words = text.split(RegExp(r'\s+'));

  // 일반적인 관사, 전치사, 대명사 등을 제외하기 위한 리스트
  Set<String> stopWords = {
    'a',
    'an',
    'the',
    'in',
    'on',
    'at',
    'to',
    'for',
    'of',
    'with',
    'by',
    'from',
    'up',
    'about',
    'into',
    'over',
    'after',
    'beneath',
    'under',
    'above',
    'I',
    'you',
    'he',
    'she',
    'it',
    'we',
    'they',
    'them',
    'my',
    'your',
    'his',
    'her',
    'its',
    'our',
    'their',
    'is',
    'am',
    'are',
    'was',
    'were',
    'be',
    'been',
    'being',
    'have',
    'has',
    'had',
    'do',
    'does',
    'did',
    'will',
    'would',
    'shall',
    'should',
    'can',
    'could',
    'may',
    'might',
    'must',
    'ought',
    'and',
    'or',
    'but',
    'because',
    'as',
    'until',
    'while',
    'if',
    'then',
    'when',
    'where',
    'why',
    'how',
    'Let\'s',
    '!',
    '?',
  };

  // 명사로 추정되는 단어들만 필터링
  List<String> nouns = words.where((word) {
    // 소문자로 변환하여 비교
    String lowercaseWord = word.toLowerCase();
    // stopWords에 포함되지 않고, 길이가 1보다 큰 단어만 선택
    return !stopWords.contains(lowercaseWord) && lowercaseWord.length > 1;
  }).toList();

  // 결과를 공백으로 구분된 문자열로 반환
  return nouns.join(' ');
}
