from flask import Flask, jsonify
from datetime import datetime

app = Flask(__name__)

@app.route('/time', methods=['GET'])
def get_time():
    return jsonify({'current_time': datetime.utcnow().isoformat() + 'Z'})