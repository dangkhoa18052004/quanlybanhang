# backend/app/__init__.py
from flask import Flask, send_from_directory
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from app.config import Config
import os 

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # Enable CORS
    CORS(app)
    
    # JWT
    jwt = JWTManager(app)
    
    # Serve static files (ảnh upload local)
    UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'uploads')
    
    @app.route('/uploads/<path:filename>')
    def uploaded_file(filename):
        return send_from_directory(UPLOAD_FOLDER, filename)
    
    # ✅ Serve Admin UI
    ADMIN_UI_FOLDER = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'admin_ui')
    
    @app.route('/admin')
    def admin_home():
        try:
            return send_from_directory(ADMIN_UI_FOLDER, 'index.html')
        except:
            return {'message': 'Admin UI not found'}, 404
    
    @app.route('/admin/<path:filename>')
    def admin_files(filename):
        try:
            return send_from_directory(ADMIN_UI_FOLDER, filename)
        except:
            return {'message': 'File not found'}, 404
    
    # Register Blueprints
    from app.routes.auth import auth_bp
    from app.routes.products import products_bp
    from app.routes.cart import cart_bp
    from app.routes.orders import orders_bp
    from app.routes.reviews import reviews_bp
    from app.routes.payment import payment_bp
    from app.routes.admin import admin_bp
    
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(products_bp, url_prefix='/api')
    app.register_blueprint(cart_bp, url_prefix='/api/cart')
    app.register_blueprint(orders_bp, url_prefix='/api/orders')
    app.register_blueprint(reviews_bp, url_prefix='/api/reviews')
    app.register_blueprint(payment_bp, url_prefix='/api/payment')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')
    
    # Home route
    @app.route('/')
    def index():
        return {
            'message': 'E-Commerce API is running!', 
            'status': 'success',
            'endpoints': {
                'auth': '/api/auth',
                'products': '/api/products',
                'categories': '/api/categories',
                'cart': '/api/cart',
                'orders': '/api/orders',
                'reviews': '/api/reviews',
                'payment': '/api/payment',
                'admin': '/api/admin'
            }
        }
    
    return app