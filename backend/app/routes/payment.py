# backend/app/routes/payment.py
from flask import Blueprint, request, jsonify, redirect
from flask_jwt_extended import get_jwt_identity
from app.models import get_db_connection, get_db_cursor
from app.utils.decorators import token_required
from datetime import datetime
import hashlib
import hmac
import json
import requests
import uuid
import traceback
import os

payment_bp = Blueprint('payment', __name__)

# 🔧 CONFIGURATION
NGROK_URL = os.getenv('NGROK_URL', 'https://your-ngrok-url.ngrok-free.app')
FRONTEND_URL = os.getenv('FRONTEND_URL', 'http://localhost:3000')

MOMO_CONFIG = {
    'partner_code': os.getenv('MOMO_PARTNER_CODE', 'MOMO'),
    'access_key': os.getenv('MOMO_ACCESS_KEY', 'F8BBA842ECF85'),
    'secret_key': os.getenv('MOMO_SECRET_KEY', 'K951B6PE1waDMi640xX08PD3vg6EkVlz'),
    'endpoint': 'https://test-payment.momo.vn/v2/gateway/api/create',
    'redirect_url': f'{NGROK_URL}/api/payment/momo/callback',
    'ipn_url': f'{NGROK_URL}/api/payment/momo/ipn',
    'request_type': 'captureWallet'
}

def generate_momo_signature(raw_signature, secret_key):
    """Tạo HMAC SHA256 signature cho MoMo"""
    h = hmac.new(
        bytes(secret_key, 'utf-8'),
        bytes(raw_signature, 'utf-8'),
        hashlib.sha256
    )
    return h.hexdigest()

def generate_payment_code():
    """Tạo mã thanh toán unique"""
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    random_str = str(uuid.uuid4())[:8].upper()
    return f'PAY{timestamp}{random_str}'


# 📝 1. CREATE ORDER & PAYMENT RECORD
@payment_bp.route('/create-order', methods=['POST'])
@token_required
def create_order_and_payment():
    """
    Tạo đơn hàng và payment record từ giỏ hàng
    
    Request Body:
    {
        "shipping_address": "123 Nguyen Hue, Q1, HCM",
        "phone": "0901234567",
        "discount_code": "SUMMER2024",
        "payment_method": "momo"
    }
    """
    try:
        user_id = get_jwt_identity()
        data = request.json
        
        shipping_address = data.get('shipping_address')
        phone = data.get('phone')
        discount_code = data.get('discount_code')
        payment_method = data.get('payment_method', 'momo')
        
        if not all([shipping_address, phone]):
            return jsonify({'error': 'Thiếu thông tin giao hàng'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # 1️⃣ Lấy giỏ hàng
                cur.execute("""
                    SELECT c.*, p.name, p.price, p.image_url, p.stock_quantity
                    FROM cart c
                    JOIN products p ON c.product_id = p.id
                    WHERE c.user_id = %s
                """, (user_id,))
                
                cart_items = cur.fetchall()
                
                if not cart_items:
                    return jsonify({'error': 'Giỏ hàng trống'}), 400
                
                # 2️⃣ Kiểm tra tồn kho
                for item in cart_items:
                    if item['stock_quantity'] < item['quantity']:
                        return jsonify({
                            'error': f"Sản phẩm '{item['name']}' không đủ số lượng"
                        }), 400
                
                # 3️⃣ Tính tổng tiền
                subtotal = sum(item['price'] * item['quantity'] for item in cart_items)
                discount_amount = 0
                
                # 4️⃣ Áp dụng mã giảm giá
                if discount_code:
                    cur.execute("""
                        SELECT * FROM discount_codes
                        WHERE code = %s 
                        AND is_active = TRUE
                        AND valid_from <= NOW()
                        AND valid_until >= NOW()
                        AND (usage_limit IS NULL OR used_count < usage_limit)
                        AND %s >= min_order_value
                    """, (discount_code, subtotal))
                    
                    discount = cur.fetchone()
                    
                    if discount:
                        discount_amount = (subtotal * discount['discount_percent']) / 100
                        
                        # Kiểm tra max_discount
                        if discount['max_discount'] and discount_amount > discount['max_discount']:
                            discount_amount = discount['max_discount']
                    else:
                        return jsonify({'error': 'Mã giảm giá không hợp lệ'}), 400
                
                total_amount = subtotal - discount_amount
                
                # 5️⃣ Tạo order number
                order_number = f'ORD{datetime.now().strftime("%Y%m%d%H%M%S")}{user_id}'
                
                # 6️⃣ Tạo Order
                cur.execute("""
                    INSERT INTO orders (
                        user_id, order_number, subtotal, discount_amount, 
                        total_amount, discount_code, shipping_address, phone,
                        payment_method, status, payment_status
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'pending', 'pending')
                    RETURNING id, order_number
                """, (
                    user_id, order_number, subtotal, discount_amount,
                    total_amount, discount_code, shipping_address, phone,
                    payment_method
                ))
                
                order = cur.fetchone()
                order_id = order['id']
                
                print(f"[CREATE ORDER] ✅ Order created: {order['order_number']} (ID: {order_id})")
                
                # 7️⃣ Tạo Order Items
                for item in cart_items:
                    cur.execute("""
                        INSERT INTO order_items (
                            order_id, product_id, product_name, product_image,
                            price, quantity, subtotal
                        )
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """, (
                        order_id, item['product_id'], item['name'], item['image_url'],
                        item['price'], item['quantity'], item['price'] * item['quantity']
                    ))
                    
                    # 8️⃣ Giảm số lượng tồn kho
                    cur.execute("""
                        UPDATE products 
                        SET stock_quantity = stock_quantity - %s
                        WHERE id = %s
                    """, (item['quantity'], item['product_id']))
                
                # 9️⃣ Tăng usage count của discount code
                if discount_code and discount:
                    cur.execute("""
                        UPDATE discount_codes 
                        SET used_count = used_count + 1
                        WHERE code = %s
                    """, (discount_code,))
                
                # 🔟 Xóa giỏ hàng
                cur.execute("DELETE FROM cart WHERE user_id = %s", (user_id,))
                
                # 1️⃣1️⃣ Tạo Payment Record
                payment_code = generate_payment_code()
                
                cur.execute("""
                    INSERT INTO payments (
                        payment_code, order_id, user_id, amount,
                        payment_method, payment_status, description
                    )
                    VALUES (%s, %s, %s, %s, %s, 'pending', %s)
                    RETURNING id, payment_code
                """, (
                    payment_code, order_id, user_id, total_amount,
                    payment_method, f'Thanh toán đơn hàng {order_number}'
                ))
                
                payment = cur.fetchone()
                
                print(f"[CREATE PAYMENT] ✅ Payment record created: {payment['payment_code']}")
                
                return jsonify({
                    'message': 'Tạo đơn hàng thành công',
                    'order': {
                        'id': order_id,
                        'order_number': order['order_number'],
                        'total_amount': float(total_amount)
                    },
                    'payment': {
                        'id': payment['id'],
                        'payment_code': payment['payment_code'],
                        'amount': float(total_amount)
                    }
                }), 201
                
    except Exception as e:
        print(f"[ERROR] Failed to create order: {str(e)}")
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


# 💳 2. INITIATE MOMO PAYMENT
@payment_bp.route('/initiate-momo', methods=['POST'])
@token_required
def initiate_momo_payment():
    """
    Khởi tạo thanh toán MoMo
    
    Request Body:
    {
        "payment_code": "PAY20241126123456ABC"
    }
    """
    try:
        user_id = get_jwt_identity()
        data = request.json
        payment_code = data.get('payment_code')
        
        if not payment_code:
            return jsonify({'error': 'payment_code là bắt buộc'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Lấy thông tin payment
                cur.execute("""
                    SELECT p.*, o.order_number
                    FROM payments p
                    JOIN orders o ON p.order_id = o.id
                    WHERE p.payment_code = %s AND p.user_id = %s
                """, (payment_code, user_id))
                
                payment = cur.fetchone()
                
                if not payment:
                    return jsonify({'error': 'Payment không tồn tại'}), 404
                
                # Kiểm tra status
                if payment['payment_status'] == 'completed':
                    return jsonify({'error': 'Payment đã được thanh toán'}), 400
                
                if payment['payment_status'] == 'processing':
                    return jsonify({
                        'message': 'Payment đang được xử lý',
                        'status': 'processing'
                    }), 200
                
                # Tạo MoMo request
                order_id = payment['payment_code']
                request_id = str(uuid.uuid4())
                amount = str(int(float(payment['amount'])))
                order_info = f"Thanh toán đơn hàng {payment['order_number']}"
                extra_data = ""
                
                # Tạo signature
                raw_signature = (
                    f"accessKey={MOMO_CONFIG['access_key']}"
                    f"&amount={amount}"
                    f"&extraData={extra_data}"
                    f"&ipnUrl={MOMO_CONFIG['ipn_url']}"
                    f"&orderId={order_id}"
                    f"&orderInfo={order_info}"
                    f"&partnerCode={MOMO_CONFIG['partner_code']}"
                    f"&redirectUrl={MOMO_CONFIG['redirect_url']}"
                    f"&requestId={request_id}"
                    f"&requestType={MOMO_CONFIG['request_type']}"
                )
                
                signature = generate_momo_signature(raw_signature, MOMO_CONFIG['secret_key'])
                
                # Request body
                momo_data = {
                    'partnerCode': MOMO_CONFIG['partner_code'],
                    'partnerName': "E-Commerce Shop",
                    'storeId': "OnlineStore",
                    'requestId': request_id,
                    'amount': amount,
                    'orderId': order_id,
                    'orderInfo': order_info,
                    'redirectUrl': MOMO_CONFIG['redirect_url'],
                    'ipnUrl': MOMO_CONFIG['ipn_url'],
                    'lang': 'vi',
                    'extraData': extra_data,
                    'requestType': MOMO_CONFIG['request_type'],
                    'signature': signature
                }
                
                print(f"[MOMO REQUEST] Payment Code: {payment_code}")
                print(f"[MOMO REQUEST] Amount: {amount} VND")
                
                # Gửi request đến MoMo
                json_data = json.dumps(momo_data)
                response = requests.post(
                    MOMO_CONFIG['endpoint'],
                    data=json_data,
                    headers={
                        'Content-Type': 'application/json',
                        'Content-Length': str(len(json_data))
                    },
                    timeout=10
                )
                
                result = response.json()
                
                print(f"[MOMO RESPONSE] Result Code: {result.get('resultCode')}")
                
                if result.get('resultCode') == 0:
                    # Cập nhật payment status
                    cur.execute("""
                        UPDATE payments 
                        SET payment_status = 'processing', transaction_id = %s
                        WHERE payment_code = %s
                    """, (request_id, payment_code))
                    
                    print(f"[MOMO SUCCESS] ✅ Payment URL generated")
                    
                    return jsonify({
                        'message': 'Khởi tạo thanh toán MoMo thành công',
                        'payment_url': result.get('payUrl'),
                        'qr_code_url': result.get('qrCodeUrl'),
                        'deeplink': result.get('deeplink'),
                        'request_id': request_id
                    }), 200
                else:
                    return jsonify({
                        'error': 'Khởi tạo thanh toán thất bại',
                        'message': result.get('message'),
                        'result_code': result.get('resultCode')
                    }), 400
                    
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Connection error: {str(e)}")
        return jsonify({'error': f'Lỗi kết nối: {str(e)}'}), 500
    except Exception as e:
        print(f"[ERROR] {str(e)}")
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


# ✅ 3. MOMO CALLBACK
@payment_bp.route('/momo/callback', methods=['GET'])
def momo_payment_callback():
    """Xử lý callback từ MoMo sau khi user thanh toán"""
    
    # Lấy parameters từ URL
    partner_code = request.args.get('partnerCode')
    order_id = request.args.get('orderId')  # payment_code
    request_id = request.args.get('requestId')
    amount = request.args.get('amount')
    order_info = request.args.get('orderInfo')
    order_type = request.args.get('orderType')
    trans_id = request.args.get('transId')
    result_code = request.args.get('resultCode')
    message = request.args.get('message')
    pay_type = request.args.get('payType')
    response_time = request.args.get('responseTime')
    extra_data = request.args.get('extraData', '')
    signature = request.args.get('signature')
    
    print("=" * 60)
    print(f"[CALLBACK] Order ID: {order_id}, Result: {result_code}")
    print(f"[CALLBACK] Trans ID: {trans_id}")
    print(f"[CALLBACK] Message: {message}")
    print("=" * 60)
    
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Tìm payment
                cur.execute("""
                    SELECT * FROM payments WHERE payment_code = %s
                """, (order_id,))
                
                payment = cur.fetchone()
                
                if not payment:
                    print(f"[ERROR] Payment not found: {order_id}")
                    return redirect(f'{FRONTEND_URL}/payment/failed?msg=Payment not found')
                
                # Verify signature
                raw_signature = (
                    f"accessKey={MOMO_CONFIG['access_key']}"
                    f"&amount={amount}"
                    f"&extraData={extra_data}"
                    f"&message={message}"
                    f"&orderId={order_id}"
                    f"&orderInfo={order_info}"
                    f"&orderType={order_type}"
                    f"&partnerCode={partner_code}"
                    f"&payType={pay_type}"
                    f"&requestId={request_id}"
                    f"&responseTime={response_time}"
                    f"&resultCode={result_code}"
                    f"&transId={trans_id}"
                )
                
                expected_signature = generate_momo_signature(raw_signature, MOMO_CONFIG['secret_key'])
                
                print(f"[VERIFY] Expected: {expected_signature}")
                print(f"[VERIFY] Received: {signature}")
                
                if signature != expected_signature:
                    print("[ERROR] Signature mismatch!")
                    return redirect(f'{FRONTEND_URL}/payment/failed?msg=Invalid signature')
                
                # Cập nhật database
                if result_code == '0':
                    # Thanh toán thành công
                    cur.execute("""
                        UPDATE payments
                        SET payment_status = 'completed',
                            payment_date = NOW(),
                            transaction_id = %s
                        WHERE payment_code = %s
                    """, (trans_id, order_id))
                    
                    # Cập nhật order status
                    cur.execute("""
                        UPDATE orders
                        SET payment_status = 'paid',
                            status = 'confirmed'
                        WHERE id = %s
                    """, (payment['order_id'],))
                    
                    print(f"[SUCCESS] ✅ Payment completed: {order_id}")
                    
                    return redirect(f'{FRONTEND_URL}/payment/success?order_id={payment["order_id"]}')
                else:
                    # Thanh toán thất bại
                    cur.execute("""
                        UPDATE payments
                        SET payment_status = 'failed'
                        WHERE payment_code = %s
                    """, (order_id,))
                    
                    print(f"[FAILED] ❌ Payment failed: {order_id}, Message: {message}")
                    
                    return redirect(f'{FRONTEND_URL}/payment/failed?msg={message}')
                    
    except Exception as e:
        print(f"[ERROR] Callback error: {str(e)}")
        traceback.print_exc()
        return redirect(f'{FRONTEND_URL}/payment/failed?msg=System error')


# 🔔 4. MOMO IPN (Instant Payment Notification)
@payment_bp.route('/momo/ipn', methods=['POST'])
def momo_payment_ipn():
    """Xử lý IPN từ MoMo (server-to-server callback)"""
    
    data = request.get_json()
    
    print("=" * 60)
    print("[IPN RECEIVED]")
    print(json.dumps(data, indent=2))
    print("=" * 60)
    
    partner_code = data.get('partnerCode')
    order_id = data.get('orderId')
    request_id = data.get('requestId')
    amount = str(data.get('amount'))
    order_info = data.get('orderInfo')
    order_type = data.get('orderType')
    trans_id = str(data.get('transId'))
    result_code = str(data.get('resultCode'))
    message = data.get('message')
    pay_type = data.get('payType')
    response_time = str(data.get('responseTime'))
    extra_data = data.get('extraData', '')
    signature = data.get('signature')
    
    try:
        # Verify signature
        raw_signature = (
            f"accessKey={MOMO_CONFIG['access_key']}"
            f"&amount={amount}"
            f"&extraData={extra_data}"
            f"&message={message}"
            f"&orderId={order_id}"
            f"&orderInfo={order_info}"
            f"&orderType={order_type}"
            f"&partnerCode={partner_code}"
            f"&payType={pay_type}"
            f"&requestId={request_id}"
            f"&responseTime={response_time}"
            f"&resultCode={result_code}"
            f"&transId={trans_id}"
        )
        
        expected_signature = generate_momo_signature(raw_signature, MOMO_CONFIG['secret_key'])
        
        if signature != expected_signature:
            print("[IPN ERROR] Invalid signature")
            return jsonify({'resultCode': 97, 'message': 'Invalid signature'}), 200
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Tìm payment
                cur.execute("""
                    SELECT * FROM payments WHERE payment_code = %s
                """, (order_id,))
                
                payment = cur.fetchone()
                
                if not payment:
                    print(f"[IPN ERROR] Payment not found: {order_id}")
                    return jsonify({'resultCode': 99, 'message': 'Payment not found'}), 200
                
                if result_code == '0':
                    # Thanh toán thành công
                    cur.execute("""
                        UPDATE payments
                        SET payment_status = 'completed',
                            payment_date = NOW(),
                            transaction_id = %s
                        WHERE payment_code = %s
                    """, (trans_id, order_id))
                    
                    # Cập nhật order
                    cur.execute("""
                        UPDATE orders
                        SET payment_status = 'paid',
                            status = 'confirmed'
                        WHERE id = %s
                    """, (payment['order_id'],))
                    
                    print(f"[IPN SUCCESS] ✅ Payment completed via IPN: {order_id}")
                    return jsonify({'resultCode': 0, 'message': 'Success'}), 200
                else:
                    # Thanh toán thất bại
                    cur.execute("""
                        UPDATE payments
                        SET payment_status = 'failed'
                        WHERE payment_code = %s
                    """, (order_id,))
                    
                    print(f"[IPN FAILED] ❌ Payment failed: {order_id}")
                    return jsonify({'resultCode': 0, 'message': 'Confirmed'}), 200
                    
    except Exception as e:
        print(f"[IPN ERROR] {str(e)}")
        traceback.print_exc()
        return jsonify({'resultCode': 99, 'message': 'System error'}), 200


# 📊 5. CHECK PAYMENT STATUS
@payment_bp.route('/status/<payment_code>', methods=['GET'])
@token_required
def check_payment_status(payment_code):
    """Kiểm tra trạng thái thanh toán"""
    try:
        user_id = get_jwt_identity()
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT 
                        p.*,
                        o.order_number,
                        o.total_amount as order_total
                    FROM payments p
                    JOIN orders o ON p.order_id = o.id
                    WHERE p.payment_code = %s AND p.user_id = %s
                """, (payment_code, user_id))
                
                payment = cur.fetchone()
                
                if not payment:
                    return jsonify({'error': 'Payment không tồn tại'}), 404
                
                return jsonify({
                    'payment_code': payment['payment_code'],
                    'order_number': payment['order_number'],
                    'amount': float(payment['amount']),
                    'payment_method': payment['payment_method'],
                    'payment_status': payment['payment_status'],
                    'transaction_id': payment['transaction_id'],
                    'payment_date': payment['payment_date'].strftime('%Y-%m-%d %H:%M:%S') if payment['payment_date'] else None,
                    'created_at': payment['created_at'].strftime('%Y-%m-%d %H:%M:%S')
                }), 200
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500