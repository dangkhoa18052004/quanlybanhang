# backend/app/routes/products.py
from flask import Blueprint, request, jsonify
from app.models import get_db_connection, get_db_cursor

products_bp = Blueprint('products', __name__)

@products_bp.route('/categories', methods=['GET'])
def get_categories():
    """Lấy danh sách categories"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT c.*, COUNT(p.id) as product_count
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

@products_bp.route('/products', methods=['GET'])
def get_products():
    """Lấy danh sách sản phẩm với filter và pagination"""
    try:
        # Query parameters
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 20))
        category_id = request.args.get('category_id')
        search = request.args.get('search', '').strip()
        sort_by = request.args.get('sort_by', 'newest')  # newest, price_asc, price_desc, rating
        
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
            'rating': 'p.average_rating DESC'
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
                
                # Get products
                cur.execute(f"""
                    SELECT 
                        p.*,
                        c.name as category_name,
                        (
                            SELECT json_agg(image_url)
                            FROM product_images
                            WHERE product_id = p.id
                        ) as images
                    FROM products p
                    LEFT JOIN categories c ON p.category_id = c.id
                    {where_sql}
                    ORDER BY {order_by}
                    LIMIT %s OFFSET %s
                """, params + [limit, offset])
                
                products = cur.fetchall()
                
                return jsonify({
                    'products': [dict(p) for p in products],
                    'pagination': {
                        'page': page,
                        'limit': limit,
                        'total': total,
                        'total_pages': (total + limit - 1) // limit
                    }
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@products_bp.route('/products/<int:product_id>', methods=['GET'])
def get_product_detail(product_id):
    """Lấy chi tiết sản phẩm"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Get product
                cur.execute("""
                    SELECT 
                        p.*,
                        c.name as category_name,
                        (
                            SELECT json_agg(image_url)
                            FROM product_images
                            WHERE product_id = p.id
                        ) as images
                    FROM products p
                    LEFT JOIN categories c ON p.category_id = c.id
                    WHERE p.id = %s
                """, (product_id,))
                
                product = cur.fetchone()
                
                if not product:
                    return jsonify({'error': 'Sản phẩm không tồn tại'}), 404
                
                # Get reviews
                cur.execute("""
                    SELECT 
                        r.*,
                        u.full_name as user_name
                    FROM reviews r
                    JOIN users u ON r.user_id = u.id
                    WHERE r.product_id = %s
                    ORDER BY r.created_at DESC
                    LIMIT 10
                """, (product_id,))
                
                reviews = cur.fetchall()
                
                result = dict(product)
                result['reviews'] = [dict(r) for r in reviews]
                
                return jsonify({'product': result}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500