# backend/app/routes/admin.py
from flask import Blueprint, request, jsonify
from app.utils.decorators import admin_required
from app.utils.cloudinary_helper import upload_image
from app.models import get_db_connection, get_db_cursor

admin_bp = Blueprint('admin', __name__)

@admin_bp.route('/products', methods=['POST'])
@admin_required
def create_product():
    """Tạo sản phẩm mới với upload ảnh"""
    try:
        # Lấy data từ form
        name = request.form.get('name')
        price = request.form.get('price')
        category_id = request.form.get('category_id')
        
        # Lấy file ảnh
        image_file = request.files.get('image')
        
        if not image_file:
            return jsonify({'error': 'Thiếu ảnh sản phẩm'}), 400
        
        # Upload lên Cloudinary
        image_url = upload_image(image_file, folder="ecommerce/products")
        
        # Lưu vào database
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    INSERT INTO products (name, price, category_id, image_url)
                    VALUES (%s, %s, %s, %s)
                    RETURNING id, name, image_url
                """, (name, price, category_id, image_url))
                
                product = cur.fetchone()
                
                return jsonify({
                    'message': 'Tạo sản phẩm thành công',
                    'product': dict(product)
                }), 201
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500