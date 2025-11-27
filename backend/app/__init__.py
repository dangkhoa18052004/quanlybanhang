from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from app.config import Config
import io

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    print(f"\n{'='*80}")
    print(f"[JWT SECRET KEY] {app.config['JWT_SECRET_KEY']}")
    print(f"{'='*80}\n")

    # Enable CORS
    CORS(app)
    
    # JWT
    jwt = JWTManager(app)
    
    @jwt.invalid_token_loader
    def invalid_token_callback(error_string):
        print(f"\n{'='*80}")
        print(f"[JWT ERROR] Invalid token: {error_string}")
        print(f"{'='*80}\n")
        return jsonify({'error': 'Token không hợp lệ hoặc đã hết hạn'}), 401
    
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        print(f"\n{'='*80}")
        print(f"[JWT ERROR] Token expired")
        print(f"[JWT HEADER] {jwt_header}")
        print(f"[JWT PAYLOAD] {jwt_payload}")
        print(f"{'='*80}\n")
        return jsonify({'error': 'Token đã hết hạn'}), 401
    
    @jwt.unauthorized_loader
    def missing_authorization_callback(error_string):
        print(f"\n{'='*80}")
        print(f"[JWT ERROR] Missing authorization: {error_string}")
        print(f"{'='*80}\n")
        return jsonify({'error': 'Thiếu token xác thực'}), 401
    
    @jwt.revoked_token_loader
    def revoked_token_callback(jwt_header, jwt_payload):
        print(f"\n{'='*80}")
        print(f"[JWT ERROR] Token revoked")
        print(f"{'='*80}\n")
        return jsonify({'error': 'Token đã bị thu hồi'}), 401
    
    @jwt.token_verification_failed_loader
    def token_verification_failed_callback(jwt_header, jwt_payload):
        print(f"\n{'='*80}")
        print(f"[JWT ERROR] Token verification failed")
        print(f"[JWT HEADER] {jwt_header}")
        print(f"[JWT PAYLOAD] {jwt_payload}")
        print(f"{'='*80}\n")
        return jsonify({'error': 'Xác thực token thất bại'}), 401
    
    @app.before_request
    def log_request_info():
        print(f"\n{'='*80}")
        print(f"[REQUEST] {request.method} {request.path}")
        
        # Log headers
        auth_header = request.headers.get('Authorization')
        if auth_header:
            print(f"[AUTH HEADER] {auth_header[:50]}...")
        else:
            print(f"[AUTH HEADER] None")
        
        print(f"{'='*80}\n")
    
    # ✅ ROUTE ĐỂ SERVE ẢNH TỪ PRODUCTS TABLE
    @app.route('/api/images/products/<int:product_id>')
    def serve_product_image(product_id):
        """Serve ảnh sản phẩm từ products table"""
        try:
            from app.models import get_db_connection, get_db_cursor
            
            with get_db_connection() as conn:
                with get_db_cursor(conn) as cur:
                    cur.execute("""
                        SELECT image_url, image_content_type
                        FROM products
                        WHERE id = %s
                    """, (product_id,))
                    
                    result = cur.fetchone()
                    
                    if not result or not result['image_url']:
                        return jsonify({'error': 'Ảnh không tồn tại'}), 404
                    
                    return send_file(
                        io.BytesIO(result['image_url']),
                        mimetype=result['image_content_type'] or 'image/jpeg',
                        as_attachment=False,
                        download_name=f'product_{product_id}.jpg'
                    )
        
        except Exception as e:
            print(f"[IMAGE ERROR] {str(e)}")
            return jsonify({'error': str(e)}), 404
    
    # Register Blueprints
    from app.routes.auth import auth_bp
    from app.routes.products import products_bp
    from app.routes.cart import cart_bp
    from app.routes.orders import orders_bp
    from app.routes.reviews import reviews_bp
    from app.routes.payment import payment_bp
    from app.routes.admin import admin_bp
    from app.routes.discount import discount_bp
    
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(products_bp, url_prefix='/api')
    app.register_blueprint(cart_bp, url_prefix='/api/cart')
    app.register_blueprint(orders_bp, url_prefix='/api/orders')
    app.register_blueprint(reviews_bp, url_prefix='/api/reviews')
    app.register_blueprint(payment_bp, url_prefix='/api/payment')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')
    app.register_blueprint(discount_bp, url_prefix='/api/discount')
    
    @app.route('/')
    def index():
        return {
            'message': 'E-Commerce API is running!',
            'status': 'success'
        }
    
    return app