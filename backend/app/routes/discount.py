
## File: backend/app/routes/discount.py

from flask import Blueprint, request, jsonify
from app.utils.db import get_db_connection, get_db_cursor
from app.utils.decorators import token_required, admin_required
from datetime import datetime

discount_bp = Blueprint('discount', __name__)

# ============================================================
# PUBLIC ENDPOINTS
# ============================================================

@discount_bp.route('/validate', methods=['POST'])
@token_required
def validate_discount_code(current_user):
    """Validate a discount code"""
    try:
        data = request.get_json()
        code = data.get('code', '').strip().upper()
        order_total = float(data.get('order_total', 0))  # ← Đảm bảo là float
        
        if not code:
            return jsonify({'error': 'Vui lòng nhập mã giảm giá'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Get discount code details
                cur.execute("""
                    SELECT 
                        id, code, description, discount_type, discount_value,
                        min_order_value, max_discount_amount, usage_limit, used_count,
                        start_date, end_date, is_active
                    FROM discount_codes
                    WHERE UPPER(code) = %s
                """, (code,))
                
                discount = cur.fetchone()
                
                if not discount:
                    return jsonify({'error': 'Mã giảm giá không tồn tại'}), 404
                
                # Check if active
                if not discount['is_active']:
                    return jsonify({'error': 'Mã giảm giá đã ngừng hoạt động'}), 400
                
                # Check date range
                from datetime import datetime
                now = datetime.now()
                if discount['start_date'] and discount['start_date'] > now:
                    return jsonify({'error': 'Mã giảm giá chưa có hiệu lực'}), 400
                
                if discount['end_date'] and discount['end_date'] < now:
                    return jsonify({'error': 'Mã giảm giá đã hết hạn'}), 400
                
                # Check usage limit
                if discount['usage_limit'] and discount['used_count'] >= discount['usage_limit']:
                    return jsonify({'error': 'Mã giảm giá đã hết lượt sử dụng'}), 400
                
                # ✅ FIX: Convert min_order_value to float
                min_order_value = float(discount['min_order_value']) if discount['min_order_value'] else 0
                
                # Check minimum order value
                if order_total < min_order_value:
                    return jsonify({
                        'error': f'Đơn hàng phải từ {min_order_value:,.0f}đ trở lên'
                    }), 400
                
                # ✅ FIX: Convert all Decimal to float before calculation
                discount_value = float(discount['discount_value'])
                max_discount_amount = float(discount['max_discount_amount']) if discount['max_discount_amount'] else None
                
                # Calculate discount amount
                if discount['discount_type'] == 'percentage':
                    discount_amount = order_total * (discount_value / 100)
                    if max_discount_amount:
                        discount_amount = min(discount_amount, max_discount_amount)
                else:  # fixed
                    discount_amount = discount_value
                
                # Ensure discount doesn't exceed order total
                discount_amount = min(discount_amount, order_total)
                
                return jsonify({
                    'valid': True,
                    'discount': {
                        'id': discount['id'],
                        'code': discount['code'],
                        'description': discount['description'],
                        'discount_type': discount['discount_type'],
                        'discount_value': discount_value,
                        'discount_amount': discount_amount,
                        'final_total': order_total - discount_amount
                    }
                }), 200
                
    except Exception as e:
        print(f"[VALIDATE DISCOUNT ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@discount_bp.route('/available', methods=['GET'])
@token_required
def get_available_codes(current_user):
    """Get all available discount codes"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT 
                        code, description, discount_type, discount_value,
                        min_order_value, max_discount_amount, end_date
                    FROM active_discount_codes
                    WHERE is_currently_valid = TRUE
                    ORDER BY discount_value DESC
                """)
                
                codes = [dict(row) for row in cur.fetchall()]
                
                return jsonify({'codes': codes}), 200
                
    except Exception as e:
        print(f"[GET AVAILABLE CODES ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================================
# ADMIN ENDPOINTS
# ============================================================

@discount_bp.route('', methods=['GET'])
@token_required
@admin_required
def get_all_discount_codes(current_user):
    """Get all discount codes (admin only)"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT 
                        dc.*,
                        dus.total_uses,
                        dus.total_discount_given,
                        dus.unique_users
                    FROM discount_codes dc
                    LEFT JOIN discount_usage_stats dus ON dc.id = dus.id
                    ORDER BY dc.created_at DESC
                """)
                
                codes = [dict(row) for row in cur.fetchall()]
                
                return jsonify({'codes': codes}), 200
                
    except Exception as e:
        print(f"[GET ALL DISCOUNT CODES ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


@discount_bp.route('', methods=['POST'])
@token_required
@admin_required
def create_discount_code(current_user):
    """Create a new discount code (admin only)"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required = ['code', 'discount_type', 'discount_value']
        for field in required:
            if field not in data:
                return jsonify({'error': f'Thiếu trường {field}'}), 400
        
        code = data['code'].strip().upper()
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Check if code already exists
                cur.execute("SELECT id FROM discount_codes WHERE UPPER(code) = %s", (code,))
                if cur.fetchone():
                    return jsonify({'error': 'Mã giảm giá đã tồn tại'}), 400
                
                # Insert new discount code
                cur.execute("""
                    INSERT INTO discount_codes (
                        code, description, discount_type, discount_value,
                        min_order_value, max_discount_amount, usage_limit,
                        start_date, end_date, is_active
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING *
                """, (
                    code,
                    data.get('description'),
                    data['discount_type'],
                    data['discount_value'],
                    data.get('min_order_value', 0),
                    data.get('max_discount_amount'),
                    data.get('usage_limit'),
                    data.get('start_date'),
                    data.get('end_date'),
                    data.get('is_active', True)
                ))
                
                discount = dict(cur.fetchone())
                conn.commit()
                
                return jsonify({
                    'message': 'Tạo mã giảm giá thành công',
                    'discount': discount
                }), 201
                
    except Exception as e:
        print(f"[CREATE DISCOUNT CODE ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


@discount_bp.route('/<int:discount_id>', methods=['PUT'])
@token_required
@admin_required
def update_discount_code(current_user, discount_id):
    """Update a discount code (admin only)"""
    try:
        data = request.get_json()
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Build update query dynamically
                update_fields = []
                values = []
                
                allowed_fields = [
                    'description', 'discount_type', 'discount_value',
                    'min_order_value', 'max_discount_amount', 'usage_limit',
                    'start_date', 'end_date', 'is_active'
                ]
                
                for field in allowed_fields:
                    if field in data:
                        update_fields.append(f"{field} = %s")
                        values.append(data[field])
                
                if not update_fields:
                    return jsonify({'error': 'Không có trường nào để cập nhật'}), 400
                
                values.append(discount_id)
                
                cur.execute(f"""
                    UPDATE discount_codes 
                    SET {', '.join(update_fields)}
                    WHERE id = %s
                    RETURNING *
                """, values)
                
                discount = cur.fetchone()
                
                if not discount:
                    return jsonify({'error': 'Mã giảm giá không tồn tại'}), 404
                
                conn.commit()
                
                return jsonify({
                    'message': 'Cập nhật mã giảm giá thành công',
                    'discount': dict(discount)
                }), 200
                
    except Exception as e:
        print(f"[UPDATE DISCOUNT CODE ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


@discount_bp.route('/<int:discount_id>', methods=['DELETE'])
@token_required
@admin_required
def delete_discount_code(current_user, discount_id):
    """Delete a discount code (admin only)"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("DELETE FROM discount_codes WHERE id = %s RETURNING id", (discount_id,))
                deleted = cur.fetchone()
                
                if not deleted:
                    return jsonify({'error': 'Mã giảm giá không tồn tại'}), 404
                
                conn.commit()
                
                return jsonify({'message': 'Xóa mã giảm giá thành công'}), 200
                
    except Exception as e:
        print(f"[DELETE DISCOUNT CODE ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500


@discount_bp.route('/stats', methods=['GET'])
@token_required
@admin_required
def get_discount_stats(current_user):
    """Get discount code usage statistics (admin only)"""
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Overall stats
                cur.execute("""
                    SELECT 
                        COUNT(*) as total_codes,
                        COUNT(CASE WHEN is_active THEN 1 END) as active_codes,
                        SUM(used_count) as total_uses,
                        SUM(CASE WHEN usage_limit IS NOT NULL 
                            THEN usage_limit - used_count ELSE 0 END) as remaining_uses
                    FROM discount_codes
                """)
                
                overall = dict(cur.fetchone())
                
                # Top performing codes
                cur.execute("""
                    SELECT * FROM discount_usage_stats
                    ORDER BY total_discount_given DESC
                    LIMIT 10
                """)
                
                top_codes = [dict(row) for row in cur.fetchall()]
                
                return jsonify({
                    'overall': overall,
                    'top_codes': top_codes
                }), 200
                
    except Exception as e:
        print(f"[GET DISCOUNT STATS ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500

## Register Blueprint in __init__.py:

# backend/app/__init__.py

from app.routes.discount import discount_bp

# ... existing code ...

def create_app():
    app = Flask(__name__)
    
    # ... existing blueprints ...
    
    # Register discount blueprint
    app.register_blueprint(discount_bp, url_prefix='/api/discount')
    
    return app