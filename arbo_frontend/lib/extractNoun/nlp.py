import nltk
from nltk.tokenize import word_tokenize
from nltk.tag import pos_tag

nltk.download('punkt')
nltk.download('averaged_perceptron_tagger')
# 입력 텍스트
text = "Flutter is an open-source UI software development toolkit created by Google."

# 단어 토큰화
words = word_tokenize(text)

# 품사 태깅
tagged_words = pos_tag(words)

# 명사 추출
nouns = [word for word, pos in tagged_words if pos in ['NN', 'NNS', 'NNP', 'NNPS']]

print(nouns)
