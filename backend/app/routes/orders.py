# backend/app/routes/orders.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import get_jwt_identity
from app.models import get_db_connection, get_db_cursor
from app.utils.decorators import token_required, admin_required

orders_bp = Blueprint('orders', __name__)

@orders_bp.route('/', methods=['GET'])
@token_required
def get_orders():
    """Lấy danh sách đơn hàng của user"""
    try:
        user_id = get_jwt_identity()
        
        # Query parameters
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 10))
        status = request.args.get('status')  # pending, paid, shipping, delivered, cancelled
        
        offset = (page - 1) * limit
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Build WHERE clause
                where_clause = "WHERE user_id = %s"
                params = [user_id]
                
                if status:
                    where_clause += " AND status = %s"
                    params.append(status)
                
                # Get total count
                cur.execute(f"""
                    SELECT COUNT(*) as total
                    FROM orders
                    {where_clause}
                """, params)
                
                total = cur.fetchone()['total']
                
                # Get orders
                cur.execute(f"""
                    SELECT 
                        id, order_number, subtotal, discount_amount,
                        total_amount, status, payment_status, payment_method,
                        shipping_address, phone, created_at
                    FROM orders
                    {where_clause}
                    ORDER BY created_at DESC
                    LIMIT %s OFFSET %s
                """, params + [limit, offset])
                
                orders = cur.fetchall()
                
                # Get order items cho mỗi order
                orders_list = []
                for order in orders:
                    cur.execute("""
                        SELECT product_id, product_name, product_image,
                               price, quantity, subtotal
                        FROM order_items
                        WHERE order_id = %s
                    """, (order['id'],))
                    
                    items = cur.fetchall()
                    
                    order_dict = dict(order)
                    order_dict['items'] = [dict(item) for item in items]
                    orders_list.append(order_dict)
                
                return jsonify({
                    'orders': orders_list,
                    'pagination': {
                        'page': page,
                        'limit': limit,
                        'total': total,
                        'total_pages': (total + limit - 1) // limit
                    }
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@orders_bp.route('/<int:order_id>', methods=['GET'])
@token_required
def get_order_detail(order_id):
    """Lấy chi tiết đơn hàng"""
    try:
        user_id = get_jwt_identity()
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Get order
                cur.execute("""
                    SELECT * FROM orders
                    WHERE id = %s AND user_id = %s
                """, (order_id, user_id))
                
                order = cur.fetchone()
                
                if not order:
                    return jsonify({'error': 'Đơn hàng không tồn tại'}), 404
                
                # Get order items
                cur.execute("""
                    SELECT * FROM order_items
                    WHERE order_id = %s
                """, (order_id,))
                
                items = cur.fetchall()
                
                # Get payment info
                cur.execute("""
                    SELECT payment_code, payment_status, payment_date, transaction_id
                    FROM payments
                    WHERE order_id = %s
                """, (order_id,))
                
                payment = cur.fetchone()
                
                result = dict(order)
                result['items'] = [dict(item) for item in items]
                result['payment'] = dict(payment) if payment else None
                
                return jsonify({'order': result}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@orders_bp.route('/<int:order_id>/cancel', methods=['POST'])
@token_required
def cancel_order(order_id):
    """Hủy đơn hàng (chỉ được hủy khi status = pending)"""
    try:
        user_id = get_jwt_identity()
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Lấy thông tin order
                cur.execute("""
                    SELECT id, status, payment_status
                    FROM orders
                    WHERE id = %s AND user_id = %s
                """, (order_id, user_id))
                
                order = cur.fetchone()
                
                if not order:
                    return jsonify({'error': 'Đơn hàng không tồn tại'}), 404
                
                # Kiểm tra có thể hủy không
                if order['status'] not in ['pending']:
                    return jsonify({'error': 'Không thể hủy đơn hàng này'}), 400
                
                if order['payment_status'] == 'paid':
                    return jsonify({'error': 'Không thể hủy đơn hàng đã thanh toán'}), 400
                
                # Hoàn lại số lượng tồn kho
                cur.execute("""
                    SELECT product_id, quantity
                    FROM order_items
                    WHERE order_id = %s
                """, (order_id,))
                
                items = cur.fetchall()
                
                for item in items:
                    cur.execute("""
                        UPDATE products
                        SET stock_quantity = stock_quantity + %s
                        WHERE id = %s
                    """, (item['quantity'], item['product_id']))
                
                # Cập nhật status
                cur.execute("""
                    UPDATE orders
                    SET status = 'cancelled'
                    WHERE id = %s
                    RETURNING id, status
                """, (order_id,))
                
                updated = cur.fetchone()
                
                return jsonify({
                    'message': 'Hủy đơn hàng thành công',
                    'order': dict(updated)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500