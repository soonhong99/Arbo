from flask import Flask, request, jsonify
from flask_cors import CORS
import nltk
from nltk.tokenize import word_tokenize
from nltk.tag import pos_tag

app = Flask(__name__)
# CORS(app, resources={r"/extract_nouns": {"origins": "https://soonhong99.github.io/editedintexhtml.github.io/"}})
CORS(app)

# NLTK 데이터 다운로드 (PythonAnywhere에서 필요할 수 있음)
nltk.download('punkt', quiet=True)
nltk.download('averaged_perceptron_tagger', quiet=True)

@app.route('/extract_nouns', methods=['POST'])
def extract_nouns():
    data = request.json
    text = data['text']
    
    words = word_tokenize(text)
    tagged_words = pos_tag(words)
    
    nouns = [word for word, pos in tagged_words if pos in ['NN', 'NNS', 'NNP', 'NNPS']]
    
    return jsonify({'nouns': nouns})

# 이 부분은 로컬 테스트용이므로 PythonAnywhere에서는 필요 없습니다
# if __name__ == '__main__':
#     app.run(debug=True)