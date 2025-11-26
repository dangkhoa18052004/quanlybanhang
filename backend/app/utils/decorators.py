# backend/app/utils/decorators.py
from functools import wraps
from flask import jsonify
from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
from app.models import get_db_connection, get_db_cursor

def token_required(f):
    """Decorator kiểm tra JWT token"""
    @wraps(f)
    def decorated(*args, **kwargs):
        try:
            verify_jwt_in_request()
            return f(*args, **kwargs)
        except Exception as e:
            return jsonify({'error': 'Token không hợp lệ hoặc đã hết hạn'}), 401
    return decorated

def admin_required(f):
    """Decorator kiểm tra quyền admin"""
    @wraps(f)
    def decorated(*args, **kwargs):
        try:
            verify_jwt_in_request()
            user_id = get_jwt_identity()
            
            with get_db_connection() as conn:
                with get_db_cursor(conn) as cur:
                    cur.execute("SELECT role FROM users WHERE id = %s", (user_id,))
                    user = cur.fetchone()
                    
                    if not user or user['role'] != 'admin':
                        return jsonify({'error': 'Yêu cầu quyền admin'}), 403
            
            return f(*args, **kwargs)
        except Exception as e:
            return jsonify({'error': str(e)}), 401
    return decorated