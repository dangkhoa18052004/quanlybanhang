# backend/app/routes/admin.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import get_jwt_identity
from app.models import get_db_connection, get_db_cursor
from app.utils.decorators import admin_required
from app.utils.upload_helper import save_upload_file, delete_upload_file

admin_bp = Blueprint('admin', __name__)

@admin_bp.route('/products', methods=['POST'])
@admin_required
def create_product():
    """Tạo sản phẩm mới với upload ảnh local"""
    try:
        # Nhận dữ liệu qua form-data
        name = request.form.get('name')
        description = request.form.get('description')
        price = request.form.get('price')
        stock_quantity = request.form.get('stock_quantity', 0)
        category_id = request.form.get('category_id')
        
        if not all([name, price, category_id]):
            return jsonify({'error': 'Thiếu thông tin bắt buộc'}), 400
        
        image_file = request.files.get('image')
        image_url = None
        
        if image_file:
            image_url = save_upload_file(image_file, folder='products')
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    INSERT INTO products (
                        name, description, price, stock_quantity, 
                        category_id, image_url
                    )
                    VALUES (%s, %s, %s, %s, %s, %s)
                    RETURNING id, name, price, image_url
                """, (name, description, price, stock_quantity, category_id, image_url))
                
                product = cur.fetchone()
                
                return jsonify({
                    'message': 'Tạo sản phẩm thành công',
                    'product': dict(product)
                }), 201
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/products/<int:product_id>', methods=['PUT'])
@admin_required
def update_product(product_id):
    """Cập nhật sản phẩm (hỗ trợ multipart/form-data)"""
    try:
        name = request.form.get('name')
        description = request.form.get('description')
        price = request.form.get('price')
        stock_quantity = request.form.get('stock_quantity')
        category_id = request.form.get('category_id')
        image_file = request.files.get('image')
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT image_url FROM products WHERE id = %s
                """, (product_id,))
                
                old_product = cur.fetchone()
                
                if not old_product:
                    return jsonify({'error': 'Sản phẩm không tồn tại'}), 404
                
                new_image_url = old_product['image_url']
                
                if image_file:
                    if old_product['image_url']:
                        delete_upload_file(old_product['image_url'])
                    
                    new_image_url = save_upload_file(image_file, folder='products')
                
                cur.execute("""
                    UPDATE products
                    SET name = COALESCE(%s, name),
                        description = COALESCE(%s, description),
                        price = COALESCE(%s, price),
                        stock_quantity = COALESCE(%s, stock_quantity),
                        category_id = COALESCE(%s, category_id),
                        image_url = %s
                    WHERE id = %s
                    RETURNING id, name, price, image_url
                """, (name, description, price, stock_quantity, category_id, 
                      new_image_url, product_id))
                
                product = cur.fetchone()
                
                return jsonify({
                    'message': 'Cập nhật sản phẩm thành công',
                    'product': dict(product)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/products/<int:product_id>', methods=['DELETE'])
@admin_required
def delete_product(product_id):
    """Xóa sản phẩm"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT image_url FROM products WHERE id = %s
                """, (product_id,))
                
                product = cur.fetchone()
                
                if not product:
                    return jsonify({'error': 'Sản phẩm không tồn tại'}), 404
                
                if product['image_url']:
                    delete_upload_file(product['image_url'])
                
                # Xóa sản phẩm
                cur.execute("DELETE FROM products WHERE id = %s", (product_id,))
                
                return jsonify({'message': 'Xóa sản phẩm thành công'}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# =======================================================
# CATEGORY MANAGEMENT (CRUD - Hoàn chỉnh)
# =======================================================

@admin_bp.route('/categories', methods=['GET'])
@admin_required
def get_all_categories():
    """Lấy tất cả categories (cho admin)"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT 
                        c.*,
                        COUNT(p.id) as product_count
                    FROM categories c
                    LEFT JOIN products p ON c.id = p.category_id
                    GROUP BY c.id
                    ORDER BY c.name
                """)
                
                categories = cur.fetchall()
                
                return jsonify({
                    'categories': [dict(cat) for cat in categories]
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/categories', methods=['POST'])
@admin_required
def create_category():
    """Tạo category mới (hỗ trợ multipart/form-data)"""
    try:
        name = request.form.get('name')
        description = request.form.get('description')
        image_file = request.files.get('image')
        
        if not name:
            return jsonify({'error': 'Thiếu tên danh mục'}), 400
        
        image_url = None
        if image_file:
            image_url = save_upload_file(image_file, folder='categories')
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("SELECT id FROM categories WHERE name = %s", (name,))
                if cur.fetchone():
                    return jsonify({'error': 'Tên danh mục đã tồn tại'}), 400
                
                cur.execute("""
                    INSERT INTO categories (name, description, image_url)
                    VALUES (%s, %s, %s)
                    RETURNING id, name, description, image_url
                """, (name, description, image_url))
                
                category = cur.fetchone()
                
                return jsonify({
                    'message': 'Tạo danh mục thành công',
                    'category': dict(category)
                }), 201
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/categories/<int:category_id>', methods=['PUT'])
@admin_required
def update_category(category_id):
    """Cập nhật category"""
    try:
        name = request.form.get('name')
        description = request.form.get('description')
        image_file = request.files.get('image')
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT image_url FROM categories WHERE id = %s
                """, (category_id,))
                
                old_category = cur.fetchone()
                
                if not old_category:
                    return jsonify({'error': 'Danh mục không tồn tại'}), 404
                
                new_image_url = old_category['image_url']
                
                if image_file:
                    if old_category['image_url']:
                        delete_upload_file(old_category['image_url'])
                    
                    new_image_url = save_upload_file(image_file, folder='categories')
                
                cur.execute("""
                    UPDATE categories
                    SET name = COALESCE(%s, name),
                        description = COALESCE(%s, description),
                        image_url = %s
                    WHERE id = %s
                    RETURNING id, name, description, image_url
                """, (name, description, new_image_url, category_id))
                
                category = cur.fetchone()
                
                return jsonify({
                    'message': 'Cập nhật danh mục thành công',
                    'category': dict(category)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/categories/<int:category_id>', methods=['DELETE'])
@admin_required
def delete_category(category_id):
    """Xóa category (chỉ xóa được nếu không có product)"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT COUNT(*) as count FROM products WHERE category_id = %s
                """, (category_id,))
                
                count = cur.fetchone()['count']
                
                if count > 0:
                    return jsonify({
                        'error': f'Không thể xóa danh mục có {count} sản phẩm'
                    }), 400
                
                cur.execute("""
                    SELECT image_url FROM categories WHERE id = %s
                """, (category_id,))
                
                category = cur.fetchone()
                
                if not category:
                    return jsonify({'error': 'Danh mục không tồn tại'}), 404
                
                if category['image_url']:
                    delete_upload_file(category['image_url'])
                
                cur.execute("DELETE FROM categories WHERE id = %s", (category_id,))
                
                return jsonify({'message': 'Xóa danh mục thành công'}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@admin_bp.route('/discount-codes', methods=['GET'])
@admin_required
def get_discount_codes():
    """Lấy danh sách mã giảm giá"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT * FROM discount_codes
                    ORDER BY created_at DESC
                """)
                
                codes = cur.fetchall()
                
                return jsonify({
                    'discount_codes': [dict(code) for code in codes]
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/discount-codes', methods=['POST'])
@admin_required
def create_discount_code():
    """
    Tạo mã giảm giá mới
    
    Request Body:
    {
        "code": "SUMMER2024",
        "discount_percent": 10,
        "min_order_value": 100000,
        "max_discount": 50000,
        "valid_from": "2024-06-01T00:00:00",
        "valid_until": "2024-08-31T23:59:59",
        "usage_limit": 100
    }
    """
    try:
        data = request.json
        
        code = data.get('code')
        discount_percent = data.get('discount_percent')
        min_order_value = data.get('min_order_value', 0)
        max_discount = data.get('max_discount')
        valid_from = data.get('valid_from')
        valid_until = data.get('valid_until')
        usage_limit = data.get('usage_limit')
        
        if not all([code, discount_percent]):
            return jsonify({'error': 'Thiếu thông tin bắt buộc'}), 400
        
        if discount_percent < 1 or discount_percent > 100:
            return jsonify({'error': 'Phần trăm giảm giá phải từ 1-100'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Kiểm tra code đã tồn tại
                cur.execute("SELECT id FROM discount_codes WHERE code = %s", (code,))
                if cur.fetchone():
                    return jsonify({'error': 'Mã giảm giá đã tồn tại'}), 400
                
                # Tạo mã mới
                cur.execute("""
                    INSERT INTO discount_codes (
                        code, discount_percent, min_order_value, max_discount,
                        valid_from, valid_until, usage_limit
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    RETURNING *
                """, (code, discount_percent, min_order_value, max_discount,
                      valid_from, valid_until, usage_limit))
                
                discount_code = cur.fetchone()
                
                return jsonify({
                    'message': 'Tạo mã giảm giá thành công',
                    'discount_code': dict(discount_code)
                }), 201
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/discount-codes/<int:code_id>', methods=['PUT'])
@admin_required
def update_discount_code(code_id):
    """Cập nhật mã giảm giá"""
    try:
        data = request.json
        
        discount_percent = data.get('discount_percent')
        min_order_value = data.get('min_order_value')
        max_discount = data.get('max_discount')
        valid_from = data.get('valid_from')
        valid_until = data.get('valid_until')
        usage_limit = data.get('usage_limit')
        is_active = data.get('is_active')
        
        if discount_percent and (discount_percent < 1 or discount_percent > 100):
            return jsonify({'error': 'Phần trăm giảm giá phải từ 1-100'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    UPDATE discount_codes
                    SET discount_percent = COALESCE(%s, discount_percent),
                        min_order_value = COALESCE(%s, min_order_value),
                        max_discount = COALESCE(%s, max_discount),
                        valid_from = COALESCE(%s, valid_from),
                        valid_until = COALESCE(%s, valid_until),
                        usage_limit = COALESCE(%s, usage_limit),
                        is_active = COALESCE(%s, is_active)
                    WHERE id = %s
                    RETURNING *
                """, (discount_percent, min_order_value, max_discount,
                      valid_from, valid_until, usage_limit, is_active, code_id))
                
                discount_code = cur.fetchone()
                
                if not discount_code:
                    return jsonify({'error': 'Mã giảm giá không tồn tại'}), 404
                
                return jsonify({
                    'message': 'Cập nhật thành công',
                    'discount_code': dict(discount_code)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/discount-codes/<int:code_id>', methods=['DELETE'])
@admin_required
def delete_discount_code(code_id):
    """Xóa mã giảm giá"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    DELETE FROM discount_codes 
                    WHERE id = %s
                    RETURNING id
                """, (code_id,))
                
                deleted = cur.fetchone()
                
                if not deleted:
                    return jsonify({'error': 'Mã giảm giá không tồn tại'}), 404
                
                return jsonify({'message': 'Xóa mã giảm giá thành công'}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/discount-codes/<int:code_id>/toggle', methods=['POST'])
@admin_required
def toggle_discount_code(code_id):
    """Bật/tắt mã giảm giá"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    UPDATE discount_codes
                    SET is_active = NOT is_active
                    WHERE id = %s
                    RETURNING id, code, is_active
                """, (code_id,))
                
                discount_code = cur.fetchone()
                
                if not discount_code:
                    return jsonify({'error': 'Mã giảm giá không tồn tại'}), 404
                
                status = 'Kích hoạt' if discount_code['is_active'] else 'Vô hiệu hóa'
                
                return jsonify({
                    'message': f'{status} mã giảm giá thành công',
                    'discount_code': dict(discount_code)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@admin_bp.route('/orders', methods=['GET'])
@admin_required
def get_all_orders():
    """Lấy tất cả đơn hàng (admin)"""
    try:
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 20))
        status = request.args.get('status')
        payment_status = request.args.get('payment_status')
        search = request.args.get('search', '').strip()
        
        offset = (page - 1) * limit
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Build WHERE clause
                where_clauses = []
                params = []
                
                if status:
                    where_clauses.append("o.status = %s")
                    params.append(status)
                
                if payment_status:
                    where_clauses.append("o.payment_status = %s")
                    params.append(payment_status)
                
                if search:
                    where_clauses.append("""
                        (o.order_number ILIKE %s OR 
                         u.full_name ILIKE %s OR 
                         u.email ILIKE %s)
                    """)
                    search_param = f'%{search}%'
                    params.extend([search_param, search_param, search_param])
                
                where_sql = "WHERE " + " AND ".join(where_clauses) if where_clauses else ""
                
                # Get total
                cur.execute(f"""
                    SELECT COUNT(*) as total
                    FROM orders o
                    JOIN users u ON o.user_id = u.id
                    {where_sql}
                """, params)
                
                total = cur.fetchone()['total']
                
                # Get orders
                cur.execute(f"""
                    SELECT 
                        o.*,
                        u.full_name as customer_name,
                        u.email as customer_email
                    FROM orders o
                    JOIN users u ON o.user_id = u.id
                    {where_sql}
                    ORDER BY o.created_at DESC
                    LIMIT %s OFFSET %s
                """, params + [limit, offset])
                
                orders = cur.fetchall()
                
                return jsonify({
                    'orders': [dict(order) for order in orders],
                    'pagination': {
                        'page': page,
                        'limit': limit,
                        'total': total,
                        'total_pages': (total + limit - 1) // limit
                    }
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/orders/<int:order_id>', methods=['GET'])
@admin_required
def get_order_detail_admin(order_id):
    """Lấy chi tiết đơn hàng (admin)"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Get order
                cur.execute("""
                    SELECT 
                        o.*,
                        u.full_name as customer_name,
                        u.email as customer_email,
                        u.phone as customer_phone
                    FROM orders o
                    JOIN users u ON o.user_id = u.id
                    WHERE o.id = %s
                """, (order_id,))
                
                order = cur.fetchone()
                
                if not order:
                    return jsonify({'error': 'Đơn hàng không tồn tại'}), 404
                
                # Get order items
                cur.execute("""
                    SELECT * FROM order_items WHERE order_id = %s
                """, (order_id,))
                
                items = cur.fetchall()
                
                # Get payment
                cur.execute("""
                    SELECT * FROM payments WHERE order_id = %s
                """, (order_id,))
                
                payment = cur.fetchone()
                
                result = dict(order)
                result['items'] = [dict(item) for item in items]
                result['payment'] = dict(payment) if payment else None
                
                return jsonify({'order': result}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/orders/<int:order_id>/status', methods=['PUT'])
@admin_required
def update_order_status(order_id):
    """
    Cập nhật trạng thái đơn hàng
    
    Request Body:
    {
        "status": "shipping"  // pending, confirmed, shipping, delivered, cancelled
    }
    """
    try:
        data = request.json
        status = data.get('status')
        
        valid_statuses = ['pending', 'confirmed', 'shipping', 'delivered', 'cancelled']
        
        if status not in valid_statuses:
            return jsonify({'error': f'Status không hợp lệ. Chỉ chấp nhận: {", ".join(valid_statuses)}'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    UPDATE orders
                    SET status = %s
                    WHERE id = %s
                    RETURNING id, order_number, status
                """, (status, order_id))
                
                order = cur.fetchone()
                
                if not order:
                    return jsonify({'error': 'Đơn hàng không tồn tại'}), 404
                
                return jsonify({
                    'message': f'Cập nhật trạng thái thành công: {status}',
                    'order': dict(order)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@admin_bp.route('/users', methods=['GET'])
@admin_required
def get_all_users():
    """Lấy danh sách users"""
    try:
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 20))
        role = request.args.get('role')  # customer, admin
        search = request.args.get('search', '').strip()
        
        offset = (page - 1) * limit
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Build WHERE
                where_clauses = []
                params = []
                
                if role:
                    where_clauses.append("role = %s")
                    params.append(role)
                
                if search:
                    where_clauses.append("""
                        (full_name ILIKE %s OR email ILIKE %s OR phone ILIKE %s)
                    """)
                    search_param = f'%{search}%'
                    params.extend([search_param, search_param, search_param])
                
                where_sql = "WHERE " + " AND ".join(where_clauses) if where_clauses else ""
                
                # Get total
                cur.execute(f"""
                    SELECT COUNT(*) as total FROM users {where_sql}
                """, params)
                
                total = cur.fetchone()['total']
                
                # Get users
                cur.execute(f"""
                    SELECT 
                        id, email, full_name, phone, address, role, created_at
                    FROM users
                    {where_sql}
                    ORDER BY created_at DESC
                    LIMIT %s OFFSET %s
                """, params + [limit, offset])
                
                users = cur.fetchall()
                
                return jsonify({
                    'users': [dict(user) for user in users],
                    'pagination': {
                        'page': page,
                        'limit': limit,
                        'total': total,
                        'total_pages': (total + limit - 1) // limit
                    }
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/users/<int:user_id>', methods=['GET'])
@admin_required
def get_user_detail(user_id):
    """Lấy chi tiết user"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT 
                        id, email, full_name, phone, address, role, created_at
                    FROM users WHERE id = %s
                """, (user_id,))
                
                user = cur.fetchone()
                
                if not user:
                    return jsonify({'error': 'User không tồn tại'}), 404
                
                # Get statistics
                cur.execute("""
                    SELECT 
                        COUNT(*) as total_orders,
                        COALESCE(SUM(total_amount), 0) as total_spent
                    FROM orders
                    WHERE user_id = %s AND payment_status = 'paid'
                """, (user_id,))
                
                stats = cur.fetchone()
                
                result = dict(user)
                result['stats'] = dict(stats)
                
                return jsonify({'user': result}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/users/<int:user_id>/role', methods=['PUT'])
@admin_required
def update_user_role(user_id):
    """
    Cập nhật role của user
    
    Request Body:
    {
        "role": "admin"  // customer or admin
    }
    """
    try:
        data = request.json
        role = data.get('role')
        
        if role not in ['customer', 'admin']:
            return jsonify({'error': 'Role không hợp lệ'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    UPDATE users
                    SET role = %s
                    WHERE id = %s
                    RETURNING id, email, full_name, role
                """, (role, user_id))
                
                user = cur.fetchone()
                
                if not user:
                    return jsonify({'error': 'User không tồn tại'}), 404
                
                return jsonify({
                    'message': f'Cập nhật role thành công: {role}',
                    'user': dict(user)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@admin_bp.route('/dashboard/stats', methods=['GET'])
@admin_required
def get_dashboard_stats():
    """Lấy thống kê tổng quan"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Tổng doanh thu
                cur.execute("""
                    SELECT COALESCE(SUM(total_amount), 0) as total_revenue
                    FROM orders
                    WHERE payment_status = 'paid'
                """)
                revenue = cur.fetchone()['total_revenue']
                
                # Tổng đơn hàng
                cur.execute("SELECT COUNT(*) as total FROM orders")
                total_orders = cur.fetchone()['total']
                
                # Đơn hàng pending
                cur.execute("""
                    SELECT COUNT(*) as total FROM orders WHERE status = 'pending'
                """)
                pending_orders = cur.fetchone()['total']
                
                # Tổng sản phẩm
                cur.execute("SELECT COUNT(*) as total FROM products")
                total_products = cur.fetchone()['total']
                
                # Tổng users
                cur.execute("""
                    SELECT COUNT(*) as total FROM users WHERE role = 'customer'
                """)
                total_customers = cur.fetchone()['total']
                
                # Sản phẩm sắp hết hàng
                cur.execute("""
                    SELECT COUNT(*) as total FROM products WHERE stock_quantity < 10
                """)
                low_stock = cur.fetchone()['total']
                
                # Doanh thu 7 ngày gần đây
                cur.execute("""
                    SELECT 
                        DATE(created_at) as date,
                        COALESCE(SUM(total_amount), 0) as revenue,
                        COUNT(*) as orders
                    FROM orders
                    WHERE payment_status = 'paid'
                    AND created_at >= CURRENT_DATE - INTERVAL '7 days'
                    GROUP BY DATE(created_at)
                    ORDER BY date DESC
                """)
                daily_revenue = cur.fetchall()
                
                # Top 5 sản phẩm bán chạy
                cur.execute("""
                    SELECT 
                        p.id,
                        p.name,
                        p.image_url,
                        p.price,
                        SUM(oi.quantity) as total_sold
                    FROM order_items oi
                    JOIN products p ON oi.product_id = p.id
                    JOIN orders o ON oi.order_id = o.id
                    WHERE o.payment_status = 'paid'
                    GROUP BY p.id, p.name, p.image_url, p.price
                    ORDER BY total_sold DESC
                    LIMIT 5
                """)
                top_products = cur.fetchall()
                
                return jsonify({
                    'stats': {
                        'total_revenue': float(revenue),
                        'total_orders': total_orders,
                        'pending_orders': pending_orders,
                        'total_products': total_products,
                        'total_customers': total_customers,
                        'low_stock_products': low_stock
                    },
                    'daily_revenue': [dict(row) for row in daily_revenue],
                    'top_products': [dict(row) for row in top_products]
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/dashboard/revenue', methods=['GET'])
@admin_required
def get_revenue_report():
    """
    Báo cáo doanh thu theo thời gian
    
    Query Params:
    - period: day, week, month, year
    - start_date: YYYY-MM-DD
    - end_date: YYYY-MM-DD
    """
    try:
        period = request.args.get('period', 'day')
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                if period == 'day':
                    # Doanh thu theo ngày
                    cur.execute("""
                        SELECT 
                            DATE(created_at) as period,
                            COALESCE(SUM(total_amount), 0) as revenue,
                            COUNT(*) as orders
                        FROM orders
                        WHERE payment_status = 'paid'
                        AND created_at BETWEEN %s AND %s
                        GROUP BY DATE(created_at)
                        ORDER BY period DESC
                    """, (start_date, end_date))
                elif period == 'month':
                    # Doanh thu theo tháng
                    cur.execute("""
                        SELECT 
                            TO_CHAR(created_at, 'YYYY-MM') as period,
                            COALESCE(SUM(total_amount), 0) as revenue,
                            COUNT(*) as orders
                        FROM orders
                        WHERE payment_status = 'paid'
                        AND created_at BETWEEN %s AND %s
                        GROUP BY TO_CHAR(created_at, 'YYYY-MM')
                        ORDER BY period DESC
                    """, (start_date, end_date))
                else:
                    return jsonify({'error': 'Period không hợp lệ'}), 400
                
                data = cur.fetchall()
                
                return jsonify({
                    'period': period,
                    'data': [dict(row) for row in data]
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
