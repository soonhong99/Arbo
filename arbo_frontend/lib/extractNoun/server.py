from flask import Flask, request, jsonify
from flask_cors import CORS
import nltk
from nltk.tokenize import word_tokenize
from nltk.tag import pos_tag

app = Flask(__name__)
CORS(app) 

@app.route('/extract_nouns', methods=['POST'])
def extract_nouns():
    data = request.json
    text = data['text']
    
    # 단어 토큰화 및 품사 태깅
    words = word_tokenize(text)
    tagged_words = pos_tag(words)
    
    # 명사 추출
    nouns = [word for word, pos in tagged_words if pos in ['NN', 'NNS', 'NNP', 'NNPS']]
    
    return jsonify({'nouns': nouns})

if __name__ == '__main__':
    app.run(debug=True)
