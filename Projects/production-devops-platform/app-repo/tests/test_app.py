import pytest
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home(client):
    """Test home endpoint"""
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert 'service' in data
    assert 'version' in data
    assert data['status'] == 'healthy'

def test_health(client):
    """Test health endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'ok'

def test_get_users(client):
    """Test get users endpoint"""
    response = client.get('/api/users')
    assert response.status_code == 200
    data = response.get_json()
    assert 'users' in data
    assert 'count' in data
    assert data['count'] == 3

def test_create_user_success(client):
    """Test create user with valid data"""
    response = client.post('/api/users', 
                          json={'name': 'Test User', 'email': 'test@example.com'})
    assert response.status_code == 201
    data = response.get_json()
    assert data['message'] == 'User created successfully'

def test_create_user_invalid(client):
    """Test create user with invalid data"""
    response = client.post('/api/users', json={'name': 'Test User'})
    assert response.status_code == 400
    data = response.get_json()
    assert 'error' in data

def test_metrics(client):
    """Test metrics endpoint"""
    response = client.get('/api/metrics')
    assert response.status_code == 200
    data = response.get_json()
    assert 'requests_total' in data
    assert 'errors_total' in data

def test_not_found(client):
    """Test 404 error"""
    response = client.get('/nonexistent')
    assert response.status_code == 404
    data = response.get_json()
    assert 'error' in data
