from flask import Flask, jsonify, request
import logging
import os
import time
from datetime import datetime

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Application metadata
VERSION = os.getenv('APP_VERSION', '1.0.0')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'development')

@app.route('/')
def home():
    logger.info(f"Home endpoint accessed - Version: {VERSION}")
    return jsonify({
        "service": "Production DevOps Platform",
        "version": VERSION,
        "environment": ENVIRONMENT,
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat()
    })

@app.route('/health')
def health():
    return jsonify({"status": "ok"}), 200

@app.route('/api/users', methods=['GET'])
def get_users():
    logger.info("Fetching users list")
    users = [
        {"id": 1, "name": "Alice", "email": "alice@example.com"},
        {"id": 2, "name": "Bob", "email": "bob@example.com"},
        {"id": 3, "name": "Charlie", "email": "charlie@example.com"}
    ]
    return jsonify({"users": users, "count": len(users)}), 200

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    if not data or 'name' not in data or 'email' not in data:
        logger.error("Invalid user data received")
        return jsonify({"error": "Name and email are required"}), 400
    
    logger.info(f"Creating user: {data['name']}")
    return jsonify({
        "message": "User created successfully",
        "user": data
    }), 201

@app.route('/api/metrics')
def metrics():
    return jsonify({
        "requests_total": 1000,
        "errors_total": 5,
        "response_time_avg": 0.25,
        "uptime_seconds": 86400
    }), 200

@app.errorhandler(404)
def not_found(error):
    logger.warning(f"404 error: {request.url}")
    return jsonify({"error": "Resource not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"500 error: {str(error)}")
    return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    logger.info(f"Starting application - Version: {VERSION}, Environment: {ENVIRONMENT}")
    app.run(host='0.0.0.0', port=5000, debug=(ENVIRONMENT == 'development'))
