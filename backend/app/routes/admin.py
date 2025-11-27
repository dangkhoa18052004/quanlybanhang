# backend/app/routes/admin.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import get_jwt_identity
from app.models import get_db_connection, get_db_cursor
from app.utils.decorators import admin_required
from app.utils.simple_image_helper import process_image_for_db

admin_bp = Blueprint('admin', __name__)

# =======================================================
# PRODUCTS MANAGEMENT
# =======================================================

@admin_bp.route('/products', methods=['POST'])
@admin_required
def create_product():
    """Tạo sản phẩm mới - lưu ảnh trực tiếp vào products"""
    try:
        name = request.form.get('name')
        description = request.form.get('description')
        price = request.form.get('price')
        stock_quantity = request.form.get('stock_quantity', 0)
        category_id = request.form.get('category_id')
        
        if not all([name, price, category_id]):
            return jsonify({'error': 'Thiếu thông tin bắt buộc'}), 400
        
        image_file = request.files.get('image')
        image_data = None
        content_type = None
        
        if image_file:
            image_data, content_type = process_image_for_db(image_file)
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    INSERT INTO products (
                        name, description, price, stock_quantity, 
                        category_id, image_url, image_content_type
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    RETURNING id, name, price
                """, (name, description, price, stock_quantity, category_id, 
                      image_data, content_type))
                
                product = cur.fetchone()
                result = dict(product)
                result['has_image'] = image_data is not None
                
                return jsonify({
                    'message': 'Tạo sản phẩm thành công',
                    'product': result
                }), 201
                
    except Exception as e:
        print(f"[CREATE PRODUCT ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/products/<int:product_id>', methods=['PUT'])
@admin_required
def update_product(product_id):
    """Cập nhật sản phẩm"""
    try:
        name = request.form.get('name')
        description = request.form.get('description')
        price = request.form.get('price')
        stock_quantity = request.form.get('stock_quantity')
        category_id = request.form.get('category_id')
        image_file = request.files.get('image')
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("SELECT id FROM products WHERE id = %s", (product_id,))
                
                if not cur.fetchone():
                    return jsonify({'error': 'Sản phẩm không tồn tại'}), 404
                
                image_data = None
                content_type = None
                
                if image_file:
                    image_data, content_type = process_image_for_db(image_file)
                
                update_fields = []
                params = []
                
                if name:
                    update_fields.append("name = %s")
                    params.append(name)
                
                if description:
                    update_fields.append("description = %s")
                    params.append(description)
                
                if price:
                    update_fields.append("price = %s")
                    params.append(price)
                
                if stock_quantity is not None:
                    update_fields.append("stock_quantity = %s")
                    params.append(stock_quantity)
                
                if category_id:
                    update_fields.append("category_id = %s")
                    params.append(category_id)
                
                if image_data:
                    update_fields.append("image_url = %s")
                    params.append(image_data)
                    update_fields.append("image_content_type = %s")
                    params.append(content_type)
                
                if not update_fields:
                    return jsonify({'error': 'Không có dữ liệu để cập nhật'}), 400
                
                params.append(product_id)
                
                query = f"""
                    UPDATE products
                    SET {', '.join(update_fields)}
                    WHERE id = %s
                    RETURNING id, name, price
                """
                
                cur.execute(query, params)
                product = cur.fetchone()
                
                return jsonify({
                    'message': 'Cập nhật sản phẩm thành công',
                    'product': dict(product)
                }), 200
                
    except Exception as e:
        print(f"[UPDATE PRODUCT ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/products/<int:product_id>', methods=['DELETE'])
@admin_required
def delete_product(product_id):
    """Xóa sản phẩm"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    DELETE FROM products 
                    WHERE id = %s
                    RETURNING id
                """, (product_id,))
                
                deleted = cur.fetchone()
                
                if not deleted:
                    return jsonify({'error': 'Sản phẩm không tồn tại'}), 404
                
                return jsonify({'message': 'Xóa sản phẩm thành công'}), 200
                
    except Exception as e:
        print(f"[DELETE PRODUCT ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


# =======================================================
# CATEGORY MANAGEMENT
# =======================================================

@admin_bp.route('/categories', methods=['GET'])
@admin_required
def get_all_categories():
    """Lấy tất cả categories"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT 
                        c.id,
                        c.name,
                        c.description,
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
    """Tạo category mới"""
    try:
        name = request.form.get('name')
        description = request.form.get('description')
        
        if not name:
            return jsonify({'error': 'Thiếu tên danh mục'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("SELECT id FROM categories WHERE name = %s", (name,))
                if cur.fetchone():
                    return jsonify({'error': 'Tên danh mục đã tồn tại'}), 400
                
                cur.execute("""
                    INSERT INTO categories (name, description)
                    VALUES (%s, %s)
                    RETURNING id, name, description
                """, (name, description))
                
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
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("SELECT id FROM categories WHERE id = %s", (category_id,))
                
                if not cur.fetchone():
                    return jsonify({'error': 'Danh mục không tồn tại'}), 404
                
                cur.execute("""
                    UPDATE categories
                    SET name = COALESCE(%s, name),
                        description = COALESCE(%s, description)
                    WHERE id = %s
                    RETURNING id, name, description
                """, (name, description, category_id))
                
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
    """Xóa category"""
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
                    DELETE FROM categories 
                    WHERE id = %s
                    RETURNING id
                """, (category_id,))
                
                deleted = cur.fetchone()
                
                if not deleted:
                    return jsonify({'error': 'Danh mục không tồn tại'}), 404
                
                return jsonify({'message': 'Xóa danh mục thành công'}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# =======================================================
# ORDERS MANAGEMENT
# =======================================================

@admin_bp.route('/orders', methods=['GET'])
@admin_required
def get_all_orders():
    """Lấy tất cả đơn hàng"""
    try:
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 20))
        status = request.args.get('status')
        payment_status = request.args.get('payment_status')
        search = request.args.get('search', '').strip()
        
        offset = (page - 1) * limit
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
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
                
                cur.execute(f"""
                    SELECT COUNT(*) as total
                    FROM orders o
                    JOIN users u ON o.user_id = u.id
                    {where_sql}
                """, params)
                
                total = cur.fetchone()['total']
                
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
    """Lấy chi tiết đơn hàng"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
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
                
                cur.execute("""
                    SELECT * FROM order_items WHERE order_id = %s
                """, (order_id,))
                
                items = cur.fetchall()
                
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
    """Cập nhật trạng thái đơn hàng"""
    try:
        data = request.json
        status = data.get('status')
        
        valid_statuses = ['pending', 'confirmed', 'shipping', 'delivered', 'cancelled']
        
        if status not in valid_statuses:
            return jsonify({'error': f'Status không hợp lệ'}), 400
        
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


# =======================================================
# USERS MANAGEMENT
# =======================================================

@admin_bp.route('/users', methods=['GET'])
@admin_required
def get_all_users():
    """Lấy danh sách users"""
    try:
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 20))
        role = request.args.get('role')
        search = request.args.get('search', '').strip()
        
        offset = (page - 1) * limit
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
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
                
                cur.execute(f"""
                    SELECT COUNT(*) as total FROM users {where_sql}
                """, params)
                
                total = cur.fetchone()['total']
                
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


@admin_bp.route('/users/<int:user_id>/role', methods=['PUT'])
@admin_required
def update_user_role(user_id):
    """Cập nhật role của user"""
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


# =======================================================
# DASHBOARD STATS
# =======================================================

@admin_bp.route('/dashboard/stats', methods=['GET'])
@admin_required
def get_dashboard_stats():
    """Lấy thống kê tổng quan"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT COALESCE(SUM(total_amount), 0) as total_revenue
                    FROM orders WHERE payment_status = 'paid'
                """)
                revenue = cur.fetchone()['total_revenue']
                
                cur.execute("SELECT COUNT(*) as total FROM orders")
                total_orders = cur.fetchone()['total']
                
                cur.execute("""
                    SELECT COUNT(*) as total FROM orders WHERE status = 'pending'
                """)
                pending_orders = cur.fetchone()['total']
                
                cur.execute("SELECT COUNT(*) as total FROM products")
                total_products = cur.fetchone()['total']
                
                cur.execute("""
                    SELECT COUNT(*) as total FROM users WHERE role = 'customer'
                """)
                total_customers = cur.fetchone()['total']
                
                cur.execute("""
                    SELECT COUNT(*) as total FROM products WHERE stock_quantity < 10
                """)
                low_stock = cur.fetchone()['total']
                
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
                
                cur.execute("""
                    SELECT 
                        p.id, p.name, p.price,
                        SUM(oi.quantity) as total_sold
                    FROM order_items oi
                    JOIN products p ON oi.product_id = p.id
                    JOIN orders o ON oi.order_id = o.id
                    WHERE o.payment_status = 'paid'
                    GROUP BY p.id, p.name, p.price
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
    
@admin_bp.route('/users', methods=['POST'])
@admin_required
def create_user():
    """Tạo người dùng mới (chỉ admin)"""
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')
        full_name = data.get('full_name')
        phone = data.get('phone')
        address = data.get('address')
        role = data.get('role', 'customer')
        
        if not all([email, password, full_name]):
            return jsonify({'error': 'Thiếu thông tin bắt buộc'}), 400
        
        if role not in ['customer', 'admin']:
            return jsonify({'error': 'Role không hợp lệ'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Kiểm tra email đã tồn tại
                cur.execute("SELECT id FROM users WHERE email = %s", (email,))
                if cur.fetchone():
                    return jsonify({'error': 'Email đã tồn tại'}), 400
                
                # Hash password
                from werkzeug.security import generate_password_hash
                hashed_password = generate_password_hash(password)
                
                # ✅ SỬA: Dùng password_hash thay vì password
                cur.execute("""
                    INSERT INTO users (email, password_hash, full_name, phone, address, role)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    RETURNING id, email, full_name, phone, address, role, created_at
                """, (email, hashed_password, full_name, phone, address, role))
                
                user = cur.fetchone()
                
                return jsonify({
                    'message': 'Tạo người dùng thành công',
                    'user': dict(user)
                }), 201
                
    except Exception as e:
        print(f"[CREATE USER ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500
    
# ✅ CẬP NHẬT THÔNG TIN NGƯỜI DÙNG
@admin_bp.route('/users/<int:user_id>', methods=['PUT'])
@admin_required
def update_user_info(user_id):
    """Cập nhật thông tin người dùng"""
    try:
        data = request.json
        
        update_fields = []
        params = []
        
        if 'full_name' in data:
            update_fields.append("full_name = %s")
            params.append(data['full_name'])
        
        if 'phone' in data:
            update_fields.append("phone = %s")
            params.append(data['phone'])
        
        if 'address' in data:
            update_fields.append("address = %s")
            params.append(data['address'])
        
        if 'email' in data:
            update_fields.append("email = %s")
            params.append(data['email'])
        
        if not update_fields:
            return jsonify({'error': 'Không có dữ liệu để cập nhật'}), 400
        
        params.append(user_id)
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                query = f"""
                    UPDATE users
                    SET {', '.join(update_fields)}
                    WHERE id = %s
                    RETURNING id, email, full_name, phone, address, role, created_at
                """
                
                cur.execute(query, params)
                user = cur.fetchone()
                
                if not user:
                    return jsonify({'error': 'Người dùng không tồn tại'}), 404
                
                return jsonify({
                    'message': 'Cập nhật thành công',
                    'user': dict(user)
                }), 200
                
    except Exception as e:
        print(f"[UPDATE USER ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


# ✅ XÓA NGƯỜI DÙNG
@admin_bp.route('/users/<int:user_id>', methods=['DELETE'])
@admin_required
def delete_user(user_id):
    """Xóa người dùng"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Kiểm tra xem có đơn hàng không
                cur.execute("""
                    SELECT COUNT(*) as count FROM orders WHERE user_id = %s
                """, (user_id,))
                
                order_count = cur.fetchone()['count']
                
                if order_count > 0:
                    return jsonify({
                        'error': f'Không thể xóa người dùng có {order_count} đơn hàng'
                    }), 400
                
                # Xóa user
                cur.execute("""
                    DELETE FROM users
                    WHERE id = %s
                    RETURNING id
                """, (user_id,))
                
                deleted = cur.fetchone()
                
                if not deleted:
                    return jsonify({'error': 'Người dùng không tồn tại'}), 404
                
                return jsonify({'message': 'Xóa người dùng thành công'}), 200
                
    except Exception as e:
        print(f"[DELETE USER ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


# ✅ RESET MẬT KHẨU (Tùy chọn)
@admin_bp.route('/users/<int:user_id>/password', methods=['PUT'])
@admin_required
def reset_user_password(user_id):
    """Reset mật khẩu người dùng"""
    try:
        data = request.json
        new_password = data.get('new_password')
        
        if not new_password or len(new_password) < 6:
            return jsonify({'error': 'Mật khẩu phải có ít nhất 6 ký tự'}), 400
        
        from werkzeug.security import generate_password_hash
        hashed_password = generate_password_hash(new_password)
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # ✅ SỬA: Dùng password_hash thay vì password
                cur.execute("""
                    UPDATE users
                    SET password_hash = %s
                    WHERE id = %s
                    RETURNING id, email
                """, (hashed_password, user_id))
                
                user = cur.fetchone()
                
                if not user:
                    return jsonify({'error': 'Người dùng không tồn tại'}), 404
                
                return jsonify({
                    'message': 'Reset mật khẩu thành công'
                }), 200
                
    except Exception as e:
        print(f"[RESET PASSWORD ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500
    

@admin_bp.route('/orders/<int:order_id>/payment-status', methods=['PUT'])
@admin_required
def update_payment_status(order_id):
    """Cập nhật trạng thái thanh toán"""
    try:
        data = request.json
        payment_status = data.get('payment_status')
        
        valid_statuses = ['pending', 'processing', 'paid', 'failed']
        
        if payment_status not in valid_statuses:
            return jsonify({'error': 'Payment status không hợp lệ'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    UPDATE orders
                    SET payment_status = %s
                    WHERE id = %s
                    RETURNING id, order_number, payment_status
                """, (payment_status, order_id))
                
                order = cur.fetchone()
                
                if not order:
                    return jsonify({'error': 'Đơn hàng không tồn tại'}), 404
                
                return jsonify({
                    'message': f'Cập nhật trạng thái thanh toán thành công',
                    'order': dict(order)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

