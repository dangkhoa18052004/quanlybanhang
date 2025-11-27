# backend/app/routes/products.py
from flask import Blueprint, request, jsonify, send_file
from app.models import get_db_connection, get_db_cursor
from app.utils.decorators import admin_required, token_required
import io

products_bp = Blueprint('products', __name__)

@products_bp.route('/categories', methods=['GET'])
def get_categories():
    """Lấy danh sách categories"""
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
        print(f"[GET CATEGORIES ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


@products_bp.route('/products', methods=['GET'])
def get_products():
    """Lấy danh sách sản phẩm với filter và pagination"""
    try:
        # Query parameters
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 50))
        category_id = request.args.get('category_id')
        search = request.args.get('search', '').strip()
        sort_by = request.args.get('sort_by', 'newest')
        
        offset = (page - 1) * limit
        
        # Build query
        where_clauses = []
        params = []
        
        if category_id:
            where_clauses.append("p.category_id = %s")
            params.append(category_id)
        
        if search:
            where_clauses.append("(p.name ILIKE %s OR p.description ILIKE %s)")
            params.extend([f'%{search}%', f'%{search}%'])
        
        where_sql = "WHERE " + " AND ".join(where_clauses) if where_clauses else ""
        
        # Sorting
        order_by = {
            'newest': 'p.created_at DESC',
            'price_asc': 'p.price ASC',
            'price_desc': 'p.price DESC',
            'name': 'p.name ASC'
        }.get(sort_by, 'p.created_at DESC')
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Get total count
                cur.execute(f"""
                    SELECT COUNT(*) as total
                    FROM products p
                    {where_sql}
                """, params)
                
                total = cur.fetchone()['total']
                
                # Get products - KHÔNG lấy image_url (binary data)
                cur.execute(f"""
                    SELECT 
                        p.id,
                        p.name,
                        p.description,
                        p.price,
                        p.stock_quantity,
                        p.category_id,
                        p.created_at,
                        c.name as category_name,
                        CASE WHEN p.image_url IS NOT NULL THEN true ELSE false END as has_image
                    FROM products p
                    LEFT JOIN categories c ON p.category_id = c.id
                    {where_sql}
                    ORDER BY {order_by}
                    LIMIT %s OFFSET %s
                """, params + [limit, offset])
                
                products = cur.fetchall()
                
                # Convert sang list và thêm image URL
                products_list = []
                for product in products:
                    product_dict = dict(product)
                    # Thêm URL để lấy ảnh
                    if product_dict['has_image']:
                        product_dict['image_url'] = f'/products/{product_dict["id"]}/image'
                    else:
                        product_dict['image_url'] = None
                    products_list.append(product_dict)
                
                return jsonify({
                    'products': products_list,
                    'pagination': {
                        'page': page,
                        'limit': limit,
                        'total': total,
                        'total_pages': (total + limit - 1) // limit
                    }
                }), 200
                
    except Exception as e:
        print(f"[GET PRODUCTS ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


@products_bp.route('/products/<int:product_id>', methods=['GET'])
def get_product_detail(product_id):
    """Lấy chi tiết sản phẩm"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Get product - KHÔNG lấy image_url (binary data)
                cur.execute("""
                    SELECT 
                        p.id,
                        p.name,
                        p.description,
                        p.price,
                        p.stock_quantity,
                        p.category_id,
                        p.created_at,
                        c.name as category_name,
                        CASE WHEN p.image_url IS NOT NULL THEN true ELSE false END as has_image
                    FROM products p
                    LEFT JOIN categories c ON p.category_id = c.id
                    WHERE p.id = %s
                """, (product_id,))
                
                product = cur.fetchone()
                
                if not product:
                    return jsonify({'error': 'Sản phẩm không tồn tại'}), 404
                
                result = dict(product)
                
                # Thêm URL để lấy ảnh
                if result['has_image']:
                    result['image_url'] = f'/products/{result["id"]}/image'
                else:
                    result['image_url'] = None
                
                return jsonify({'product': result}), 200
                
    except Exception as e:
        print(f"[GET PRODUCT DETAIL ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


@products_bp.route('/products/<int:product_id>/image', methods=['GET'])
def get_product_image(product_id):
    """Lấy ảnh sản phẩm"""
    try:
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
                
                # Convert memoryview to bytes
                image_data = bytes(result['image_url'])
                content_type = result['image_content_type'] or 'image/jpeg'
                
                return send_file(
                    io.BytesIO(image_data),
                    mimetype=content_type,
                    as_attachment=False,
                    download_name=f'product_{product_id}.jpg'
                )
                
    except Exception as e:
        print(f"[GET IMAGE ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


@products_bp.route('/products/<int:product_id>', methods=['PUT', 'PATCH'])
@admin_required
def update_product(product_id):
    """Cập nhật sản phẩm (chỉ admin)"""
    try:
        data = request.json
        updates = []
        params = []
        
        # Chỉ cập nhật các trường được cung cấp
        if 'name' in data:
            updates.append("name = %s")
            params.append(data['name'])
        if 'description' in data:
            updates.append("description = %s")
            params.append(data['description'])
        if 'price' in data:
            updates.append("price = %s")
            params.append(data['price'])
        if 'stock_quantity' in data:
            updates.append("stock_quantity = %s")
            params.append(data['stock_quantity'])
        if 'category_id' in data:
            updates.append("category_id = %s")
            params.append(data['category_id'])

        if not updates:
            return jsonify({'error': 'Không có dữ liệu cập nhật'}), 400

        params.append(product_id)
        
        update_sql = ", ".join(updates)
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute(f"""
                    UPDATE products 
                    SET {update_sql}
                    WHERE id = %s
                    RETURNING id, name
                """, params)
                
                updated_product = cur.fetchone()
                
                if not updated_product:
                    return jsonify({'error': 'Không tìm thấy sản phẩm để cập nhật'}), 404
                
                return jsonify({
                    'message': 'Cập nhật sản phẩm thành công', 
                    'product': dict(updated_product)
                }), 200
                
    except Exception as e:
        print(f"[UPDATE PRODUCT ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


@products_bp.route('/products/<int:product_id>', methods=['DELETE'])
@admin_required
def delete_product(product_id):
    """Xóa sản phẩm (chỉ admin)"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Xóa sản phẩm
                cur.execute("""
                    DELETE FROM products 
                    WHERE id = %s
                    RETURNING id
                """, (product_id,))
                
                deleted = cur.fetchone()
                
                if not deleted:
                    return jsonify({'error': 'Không tìm thấy sản phẩm để xóa'}), 404
                
                return jsonify({'message': 'Xóa sản phẩm thành công'}), 200
                
    except Exception as e:
        print(f"[DELETE PRODUCT ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500