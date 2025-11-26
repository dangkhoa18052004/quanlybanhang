# backend/app/routes/auth.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, get_jwt_identity
import bcrypt
from app.models import get_db_connection, get_db_cursor
from app.utils.decorators import token_required

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    """Đăng ký tài khoản mới"""
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')
        full_name = data.get('full_name')
        phone = data.get('phone')
        
        if not all([email, password, full_name]):
            return jsonify({'error': 'Thiếu thông tin bắt buộc'}), 400
        
        # Hash password
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Kiểm tra email đã tồn tại
                cur.execute("SELECT id FROM users WHERE email = %s", (email,))
                if cur.fetchone():
                    return jsonify({'error': 'Email đã được sử dụng'}), 400
                
                # Tạo user mới
                cur.execute("""
                    INSERT INTO users (email, password_hash, full_name, phone)
                    VALUES (%s, %s, %s, %s)
                    RETURNING id, email, full_name, phone, role
                """, (email, password_hash, full_name, phone))
                
                user = cur.fetchone()
                
                # Tạo access token
                access_token = create_access_token(identity=user['id'])
                
                return jsonify({
                    'message': 'Đăng ký thành công',
                    'token': access_token,
                    'user': dict(user)
                }), 201
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    """Đăng nhập"""
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')
        
        if not all([email, password]):
            return jsonify({'error': 'Thiếu email hoặc password'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT id, email, password_hash, full_name, phone, address, role
                    FROM users WHERE email = %s
                """, (email,))
                
                user = cur.fetchone()
                
                if not user:
                    return jsonify({'error': 'Email hoặc mật khẩu không đúng'}), 401
                
                # Verify password
                if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
                    return jsonify({'error': 'Email hoặc mật khẩu không đúng'}), 401
                
                # Tạo access token
                access_token = create_access_token(identity=user['id'])
                
                # Remove password_hash khỏi response
                user_data = dict(user)
                user_data.pop('password_hash')
                
                return jsonify({
                    'message': 'Đăng nhập thành công',
                    'token': access_token,
                    'user': user_data
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/profile', methods=['GET'])
@token_required
def get_profile():
    """Lấy thông tin profile"""
    try:
        user_id = get_jwt_identity()
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT id, email, full_name, phone, address, role
                    FROM users WHERE id = %s
                """, (user_id,))
                
                user = cur.fetchone()
                
                if not user:
                    return jsonify({'error': 'User không tồn tại'}), 404
                
                return jsonify({'user': dict(user)}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/profile', methods=['PUT'])
@token_required
def update_profile():
    """Cập nhật profile"""
    try:
        user_id = get_jwt_identity()
        data = request.json
        
        full_name = data.get('full_name')
        phone = data.get('phone')
        address = data.get('address')
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    UPDATE users 
                    SET full_name = COALESCE(%s, full_name),
                        phone = COALESCE(%s, phone),
                        address = COALESCE(%s, address)
                    WHERE id = %s
                    RETURNING id, email, full_name, phone, address, role
                """, (full_name, phone, address, user_id))
                
                user = cur.fetchone()
                
                return jsonify({
                    'message': 'Cập nhật thành công',
                    'user': dict(user)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@auth_bp.route('/change-password', methods=['POST'])
@token_required
def change_password():
    """
    Đổi mật khẩu
    
    Request Body:
    {
        "old_password": "123456",
        "new_password": "newpass123"
    }
    """
    try:
        user_id = get_jwt_identity()
        data = request.json
        
        old_password = data.get('old_password')
        new_password = data.get('new_password')
        
        if not all([old_password, new_password]):
            return jsonify({'error': 'Thiếu thông tin'}), 400
        
        if len(new_password) < 6:
            return jsonify({'error': 'Mật khẩu mới phải >= 6 ký tự'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Lấy password hiện tại
                cur.execute("""
                    SELECT password_hash FROM users WHERE id = %s
                """, (user_id,))
                
                user = cur.fetchone()
                
                # Verify old password
                if not bcrypt.checkpw(old_password.encode('utf-8'), 
                                     user['password_hash'].encode('utf-8')):
                    return jsonify({'error': 'Mật khẩu cũ không đúng'}), 401
                
                # Hash new password
                new_password_hash = bcrypt.hashpw(
                    new_password.encode('utf-8'), 
                    bcrypt.gensalt()
                ).decode('utf-8')
                
                # Update
                cur.execute("""
                    UPDATE users
                    SET password_hash = %s
                    WHERE id = %s
                """, (new_password_hash, user_id))
                
                return jsonify({'message': 'Đổi mật khẩu thành công'}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/upload-avatar', methods=['POST'])
@token_required
def upload_avatar():
    """Upload ảnh đại diện"""
    try:
        user_id = get_jwt_identity()
        
        avatar_file = request.files.get('avatar')
        
        if not avatar_file:
            return jsonify({'error': 'Thiếu file ảnh'}), 400
        
        # Upload ảnh
        from app.utils.upload_helper import save_upload_file, delete_upload_file
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Lấy avatar cũ để xóa
                cur.execute("""
                    SELECT avatar_url FROM users WHERE id = %s
                """, (user_id,))
                
                user = cur.fetchone()
                
                # Xóa avatar cũ
                if user and user.get('avatar_url'):
                    delete_upload_file(user['avatar_url'])
                
                # Upload avatar mới
                avatar_url = save_upload_file(avatar_file, folder='avatars')
                
                # Update database
                cur.execute("""
                    UPDATE users
                    SET avatar_url = %s
                    WHERE id = %s
                    RETURNING id, email, full_name, avatar_url
                """, (avatar_url, user_id))
                
                updated_user = cur.fetchone()
                
                return jsonify({
                    'message': 'Upload ảnh đại diện thành công',
                    'user': dict(updated_user)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500
