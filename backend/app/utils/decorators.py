# backend/app/utils/decorators.py
from functools import wraps
from flask import jsonify
from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
from app.models import get_db_connection, get_db_cursor

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        try:
            verify_jwt_in_request()
            current_user_id = get_jwt_identity()
            
            # FIX: Chuyển đổi identity thành integer để query database
            user_id = int(current_user_id)
            
            # Lấy thông tin user từ database
            with get_db_connection() as conn:
                with get_db_cursor(conn) as cur:
                    cur.execute("""
                        SELECT id, email, full_name, phone, address, role
                        FROM users 
                        WHERE id = %s
                    """, (user_id,))
                    
                    current_user = cur.fetchone()
                    
                    if not current_user:
                        return jsonify({'error': 'User not found'}), 401
                    
                    # Chuyển đổi từ RealDictRow sang dict thường
                    current_user = dict(current_user)
                    
                    return f(current_user, *args, **kwargs)
                    
        except Exception as e:
            print(f"[TOKEN VERIFICATION ERROR] {str(e)}")
            return jsonify({'error': 'Token không hợp lệ hoặc đã hết hạn'}), 401
            
    return decorated

def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        try:
            verify_jwt_in_request()
            current_user_id = get_jwt_identity()
            
            # FIX: Chuyển đổi identity thành integer
            user_id = int(current_user_id)
            
            with get_db_connection() as conn:
                with get_db_cursor(conn) as cur:
                    cur.execute("""
                        SELECT role FROM users WHERE id = %s
                    """, (user_id,))
                    
                    user = cur.fetchone()
                    
                    if not user or user['role'] != 'admin':
                        return jsonify({'error': 'Admin access required'}), 403
                    
                    return f(*args, **kwargs)
                    
        except Exception as e:
            return jsonify({'error': str(e)}), 401
            
    return decorated