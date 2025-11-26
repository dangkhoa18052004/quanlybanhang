# backend/app/routes/cart.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import current_user, get_jwt_identity
from app.models import get_db_connection, get_db_cursor
from app.utils.decorators import token_required

cart_bp = Blueprint('cart', __name__)

@cart_bp.route('', methods=['GET'])
@token_required
def get_cart():
    """Lấy giỏ hàng của user"""
    print(f"[CART] get_cart called for user: {current_user['id']}")

    try:
        user_id = get_jwt_identity()
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT 
                        c.id,
                        c.product_id,
                        c.quantity,
                        c.added_at,
                        p.name as product_name,
                        p.price,
                        p.image_url,
                        p.stock_quantity,
                        (p.price * c.quantity) as subtotal
                    FROM cart c
                    JOIN products p ON c.product_id = p.id
                    WHERE c.user_id = %s
                    ORDER BY c.added_at DESC
                """, (user_id,))
                
                items = cur.fetchall()
                
                # Tính tổng
                total = sum(item['subtotal'] for item in items)
                
                return jsonify({
                    'items': [dict(item) for item in items],
                    'total': float(total),
                    'count': len(items)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@cart_bp.route('/add', methods=['POST'])
@token_required
def add_to_cart():
    """Thêm sản phẩm vào giỏ hàng"""
    try:
        user_id = get_jwt_identity()
        data = request.json
        
        product_id = data.get('product_id')
        quantity = data.get('quantity', 1)
        
        if not product_id:
            return jsonify({'error': 'Thiếu product_id'}), 400
        
        if quantity < 1:
            return jsonify({'error': 'Số lượng phải >= 1'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Kiểm tra sản phẩm tồn tại
                cur.execute("""
                    SELECT id, name, price, stock_quantity 
                    FROM products WHERE id = %s
                """, (product_id,))
                
                product = cur.fetchone()
                
                if not product:
                    return jsonify({'error': 'Sản phẩm không tồn tại'}), 404
                
                # Kiểm tra tồn kho
                if product['stock_quantity'] < quantity:
                    return jsonify({'error': 'Sản phẩm không đủ số lượng'}), 400
                
                # Kiểm tra đã có trong giỏ chưa
                cur.execute("""
                    SELECT id, quantity FROM cart 
                    WHERE user_id = %s AND product_id = %s
                """, (user_id, product_id))
                
                existing = cur.fetchone()
                
                if existing:
                    # Cập nhật số lượng
                    new_quantity = existing['quantity'] + quantity
                    
                    if new_quantity > product['stock_quantity']:
                        return jsonify({'error': 'Vượt quá số lượng tồn kho'}), 400
                    
                    cur.execute("""
                        UPDATE cart 
                        SET quantity = %s
                        WHERE id = %s
                        RETURNING id, quantity
                    """, (new_quantity, existing['id']))
                    
                    message = 'Cập nhật số lượng thành công'
                else:
                    # Thêm mới
                    cur.execute("""
                        INSERT INTO cart (user_id, product_id, quantity)
                        VALUES (%s, %s, %s)
                        RETURNING id, quantity
                    """, (user_id, product_id, quantity))
                    
                    message = 'Thêm vào giỏ hàng thành công'
                
                cart_item = cur.fetchone()
                
                return jsonify({
                    'message': message,
                    'cart_item': dict(cart_item)
                }), 201
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@cart_bp.route('/update/<int:cart_id>', methods=['PUT'])
@token_required
def update_cart_item(cart_id):
    """Cập nhật số lượng sản phẩm trong giỏ"""
    try:
        user_id = get_jwt_identity()
        data = request.json
        quantity = data.get('quantity')
        
        if not quantity or quantity < 1:
            return jsonify({'error': 'Số lượng không hợp lệ'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Lấy thông tin cart item
                cur.execute("""
                    SELECT c.*, p.stock_quantity
                    FROM cart c
                    JOIN products p ON c.product_id = p.id
                    WHERE c.id = %s AND c.user_id = %s
                """, (cart_id, user_id))
                
                cart_item = cur.fetchone()
                
                if not cart_item:
                    return jsonify({'error': 'Không tìm thấy sản phẩm trong giỏ'}), 404
                
                # Kiểm tra tồn kho
                if quantity > cart_item['stock_quantity']:
                    return jsonify({'error': 'Vượt quá số lượng tồn kho'}), 400
                
                # Cập nhật
                cur.execute("""
                    UPDATE cart 
                    SET quantity = %s
                    WHERE id = %s
                    RETURNING id, quantity
                """, (quantity, cart_id))
                
                updated = cur.fetchone()
                
                return jsonify({
                    'message': 'Cập nhật thành công',
                    'cart_item': dict(updated)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@cart_bp.route('/remove/<int:cart_id>', methods=['DELETE'])
@token_required
def remove_from_cart(cart_id):
    """Xóa sản phẩm khỏi giỏ hàng"""
    try:
        user_id = get_jwt_identity()
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    DELETE FROM cart 
                    WHERE id = %s AND user_id = %s
                    RETURNING id
                """, (cart_id, user_id))
                
                deleted = cur.fetchone()
                
                if not deleted:
                    return jsonify({'error': 'Không tìm thấy sản phẩm'}), 404
                
                return jsonify({'message': 'Xóa thành công'}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@cart_bp.route('/clear', methods=['DELETE'])
@token_required
def clear_cart():
    """Xóa toàn bộ giỏ hàng"""
    try:
        user_id = get_jwt_identity()
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("DELETE FROM cart WHERE user_id = %s", (user_id,))
                
                return jsonify({'message': 'Đã xóa toàn bộ giỏ hàng'}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500  