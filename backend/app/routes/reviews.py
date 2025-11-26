# backend/app/routes/reviews.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import get_jwt_identity
from app.models import get_db_connection, get_db_cursor
from app.utils.decorators import token_required

reviews_bp = Blueprint('reviews', __name__)

@reviews_bp.route('/product/<int:product_id>', methods=['GET'])
def get_product_reviews(product_id):
    """Lấy danh sách đánh giá của sản phẩm"""
    try:
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 10))
        offset = (page - 1) * limit
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Get total
                cur.execute("""
                    SELECT COUNT(*) as total
                    FROM reviews
                    WHERE product_id = %s
                """, (product_id,))
                
                total = cur.fetchone()['total']
                
                # Get reviews
                cur.execute("""
                    SELECT 
                        r.*,
                        u.full_name as user_name
                    FROM reviews r
                    JOIN users u ON r.user_id = u.id
                    WHERE r.product_id = %s
                    ORDER BY r.created_at DESC
                    LIMIT %s OFFSET %s
                """, (product_id, limit, offset))
                
                reviews = cur.fetchall()
                
                return jsonify({
                    'reviews': [dict(r) for r in reviews],
                    'pagination': {
                        'page': page,
                        'limit': limit,
                        'total': total,
                        'total_pages': (total + limit - 1) // limit
                    }
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@reviews_bp.route('/create', methods=['POST'])
@token_required
def create_review(current_user):
    """
    Tạo đánh giá cho sản phẩm
    
    Request Body:
    {
        "product_id": 1,
        "order_id": 5,
        "rating": 5,
        "comment": "Sản phẩm tốt"
    }
    """
    try:
        user_id = current_user['id']
        data = request.json
        
        product_id = data.get('product_id')
        order_id = data.get('order_id')
        rating = data.get('rating')
        comment = data.get('comment', '')
        
        if not all([product_id, order_id, rating]):
            return jsonify({'error': 'Thiếu thông tin bắt buộc'}), 400
        
        if rating < 1 or rating > 5:
            return jsonify({'error': 'Rating phải từ 1-5'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Kiểm tra order có tồn tại và đã hoàn thành
                cur.execute("""
                    SELECT id, status, payment_status
                    FROM orders
                    WHERE id = %s AND user_id = %s
                """, (order_id, user_id))
                
                order = cur.fetchone()
                
                if not order:
                    return jsonify({'error': 'Đơn hàng không tồn tại'}), 404
                
                if order['status'] != 'delivered':
                    return jsonify({'error': 'Chỉ được đánh giá khi đơn hàng đã giao'}), 400
                
                # Kiểm tra đã đánh giá chưa
                cur.execute("""
                    SELECT id FROM reviews
                    WHERE user_id = %s AND product_id = %s AND order_id = %s
                """, (user_id, product_id, order_id))
                
                if cur.fetchone():
                    return jsonify({'error': 'Bạn đã đánh giá sản phẩm này rồi'}), 400
                
                # Tạo review
                cur.execute("""
                    INSERT INTO reviews (user_id, product_id, order_id, rating, comment)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING id, rating, comment, created_at
                """, (user_id, product_id, order_id, rating, comment))
                
                review = cur.fetchone()
                
                # Cập nhật average_rating của product
                cur.execute("""
                    UPDATE products
                    SET average_rating = (
                        SELECT AVG(rating)::NUMERIC(2,1)
                        FROM reviews
                        WHERE product_id = %s
                    ),
                    total_reviews = (
                        SELECT COUNT(*)
                        FROM reviews
                        WHERE product_id = %s
                    )
                    WHERE id = %s
                """, (product_id, product_id, product_id))
                
                return jsonify({
                    'message': 'Đánh giá thành công',
                    'review': dict(review)
                }), 201
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@reviews_bp.route('/<int:review_id>', methods=['PUT'])
@token_required
def update_review(current_user,review_id):
    """Cập nhật đánh giá"""
    try:
        user_id = current_user['id']
        data = request.json
        
        rating = data.get('rating')
        comment = data.get('comment')
        
        if rating and (rating < 1 or rating > 5):
            return jsonify({'error': 'Rating phải từ 1-5'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Kiểm tra review tồn tại
                cur.execute("""
                    SELECT id, product_id FROM reviews
                    WHERE id = %s AND user_id = %s
                """, (review_id, user_id))
                
                review = cur.fetchone()
                
                if not review:
                    return jsonify({'error': 'Đánh giá không tồn tại'}), 404
                
                # Cập nhật
                cur.execute("""
                    UPDATE reviews
                    SET rating = COALESCE(%s, rating),
                        comment = COALESCE(%s, comment)
                    WHERE id = %s
                    RETURNING id, rating, comment
                """, (rating, comment, review_id))
                
                updated = cur.fetchone()
                
                # Cập nhật average_rating
                product_id = review['product_id']
                cur.execute("""
                    UPDATE products
                    SET average_rating = (
                        SELECT AVG(rating)::NUMERIC(2,1)
                        FROM reviews
                        WHERE product_id = %s
                    )
                    WHERE id = %s
                """, (product_id, product_id))
                
                return jsonify({
                    'message': 'Cập nhật thành công',
                    'review': dict(updated)
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@reviews_bp.route('/<int:review_id>', methods=['DELETE'])
@token_required
def delete_review(current_user,review_id):
    """Xóa đánh giá"""
    try:
        user_id = current_user['id']
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT product_id FROM reviews
                    WHERE id = %s AND user_id = %s
                """, (review_id, user_id))
                
                review = cur.fetchone()
                
                if not review:
                    return jsonify({'error': 'Đánh giá không tồn tại'}), 404
                
                # Xóa review
                cur.execute("DELETE FROM reviews WHERE id = %s", (review_id,))
                
                # Cập nhật average_rating
                product_id = review['product_id']
                cur.execute("""
                    UPDATE products
                    SET average_rating = (
                        SELECT COALESCE(AVG(rating)::NUMERIC(2,1), 0)
                        FROM reviews
                        WHERE product_id = %s
                    ),
                    total_reviews = (
                        SELECT COUNT(*)
                        FROM reviews
                        WHERE product_id = %s
                    )
                    WHERE id = %s
                """, (product_id, product_id, product_id))
                
                return jsonify({'message': 'Xóa thành công'}), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500