from flask import Flask, jsonify
import os
import socket
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        'message': 'Hello from ECS Fargate!',
        'hostname': socket.gethostname(),
        'timestamp': datetime.now().isoformat(),
        'version': os.environ.get('APP_VERSION', '1.0')
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)