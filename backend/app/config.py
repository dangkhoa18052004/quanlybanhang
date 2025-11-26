# backend/app/config.py
import os
from datetime import timedelta

class Config:
    # Database
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 
        'postgresql://postgres:13579@localhost:5432/flutter')
    
    # JWT - FIX: Thêm cấu hình JWT đầy đủ
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'qE4MD7n2RzxNV8vaCn3ft4LBt7qg3rbjGyk2oWk_vjY')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=7)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    JWT_TOKEN_LOCATION = ['headers']
    JWT_HEADER_NAME = 'Authorization'
    JWT_HEADER_TYPE = 'Bearer'
    JWT_ALGORITHM = 'HS256'
    
    # Tắt các tính năng không cần thiết
    JWT_COOKIE_CSRF_PROTECT = False
    JWT_CSRF_IN_COOKIES = False
    JWT_CSRF_CHECK_FORM = False
    
    # Cloudinary (Upload ảnh)
    CLOUDINARY_CLOUD_NAME = os.getenv('CLOUDINARY_CLOUD_NAME')
    CLOUDINARY_API_KEY = os.getenv('CLOUDINARY_API_KEY')
    CLOUDINARY_API_SECRET = os.getenv('CLOUDINARY_API_SECRET')
    
    # MoMo Payment
    MOMO_ENDPOINT = 'https://test-payment.momo.vn/v2/gateway/api/create'
    MOMO_REDIRECT_URL = os.getenv('MOMO_REDIRECT_URL', 'http://localhost:3000/payment-result')
    MOMO_IPN_URL = os.getenv('MOMO_IPN_URL', 'http://localhost:5000/api/payment/momo/ipn')
    MOMO_PARTNER_CODE = os.getenv('MOMO_PARTNER_CODE', 'MOMO')
    MOMO_ACCESS_KEY = os.getenv('MOMO_ACCESS_KEY', 'F8BBA842ECF85')
    MOMO_SECRET_KEY = os.getenv('MOMO_SECRET_KEY', 'K951B6PE1waDMi640xX08PD3vg6EkVlz')
    
    # URLs
    NGROK_URL = os.getenv('NGROK_URL', 'https://your-ngrok-url.ngrok-free.app')
    FRONTEND_URL = os.getenv('FRONTEND_URL', 'http://localhost:3000')