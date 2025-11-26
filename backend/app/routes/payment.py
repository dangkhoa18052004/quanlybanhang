from flask import Blueprint, request, jsonify, redirect
from app.utils.decorators import token_required
from datetime import datetime
import hmac
import hashlib
import json
import time
import requests
import qrcode
import io
import base64
import os
import traceback
from ..models import get_db_connection, get_db_cursor

payment_bp = Blueprint('payment', __name__)

NGROK_URL = os.getenv('NGROK_URL', 'https://anika-unfinical-kala.ngrok-free.dev')
FRONTEND_URL = os.getenv('FRONTEND_URL', 'http://localhost:3000')

MOMO_PARTNER_CODE = os.getenv('MOMO_PARTNER_CODE', "MOMO") 
MOMO_ACCESS_KEY = os.getenv('MOMO_ACCESS_KEY', "F8BBA842ECF85") 
MOMO_SECRET_KEY = os.getenv('MOMO_SECRET_KEY', "K951B6PE1waDMi640xX08PD3vg6EkVlz") 
MOMO_ENDPOINT = "https://test-payment.momo.vn/v2/gateway/api/create"

# Dùng Ngrok URL cho Callback và IPN
MOMO_RETURN_URL = f"{NGROK_URL}/api/payment/momo-return"
MOMO_NOTIFY_URL = f"{NGROK_URL}/api/payment/momo-notify"

def generate_momo_signature(raw_signature, secret_key):
    """Tạo HMAC SHA256 signature cho MoMo"""
    h = hmac.new(
        bytes(secret_key, 'utf-8'),
        bytes(raw_signature, 'utf-8'),
        hashlib.sha256
    )
    return h.hexdigest()

# ----------------------------------------------------------------------
## 1. Tạo Đơn hàng và Payment Record

@payment_bp.route('/create-order', methods=['POST'])
@token_required
def create_order_with_payment(current_user):
    try:
        data = request.get_json()
        
        # ✅ Log request data
        print(f"[CREATE ORDER] User: {current_user['id']}")
        print(f"[CREATE ORDER] Data: {data}")
        
        shipping_address = data.get('shipping_address')
        phone = data.get('phone')
        discount_code = (data.get('discount_code') or '').strip().upper()
        payment_method = data.get('payment_method', 'cod')
        
        # ✅ Log validation
        print(f"[CREATE ORDER] Address: {shipping_address}")
        print(f"[CREATE ORDER] Phone: {phone}")
        print(f"[CREATE ORDER] Discount: {discount_code}")
        print(f"[CREATE ORDER] Method: {payment_method}")
        
        if not shipping_address or not phone:
            print("[CREATE ORDER ERROR] Missing shipping info")
            return jsonify({'error': 'Thiếu thông tin giao hàng'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Get cart items
                cur.execute("""
                    SELECT c.*, p.name, p.price, p.stock_quantity, p.image_url
                    FROM cart c
                    JOIN products p ON c.product_id = p.id
                    WHERE c.user_id = %s
                """, (current_user['id'],))
                
                cart_items = cur.fetchall()
                
                # ✅ Log cart
                print(f"[CREATE ORDER] Cart items count: {len(cart_items)}")
                
                if not cart_items:
                    print("[CREATE ORDER ERROR] Cart is empty")
                    return jsonify({'error': 'Giỏ hàng trống'}), 400
                
                # Calculate subtotal with float conversion
                subtotal = sum(float(item['price']) * item['quantity'] for item in cart_items)
                
                # VALIDATE & APPLY DISCOUNT CODE
                discount_amount = 0
                discount_id = None
                
                if discount_code:
                    cur.execute("""
                        SELECT 
                            id, discount_type, discount_value,
                            min_order_value, max_discount_amount,
                            usage_limit, used_count, start_date, end_date, is_active
                        FROM discount_codes
                        WHERE UPPER(code) = %s
                    """, (discount_code,))
                    
                    discount = cur.fetchone()
                    
                    if not discount:
                        return jsonify({'error': 'Mã giảm giá không tồn tại'}), 400
                    
                    # Validate discount
                    now = datetime.now()
                    
                    if not discount['is_active']:
                        return jsonify({'error': 'Mã giảm giá đã ngừng hoạt động'}), 400
                    
                    if discount['start_date'] and discount['start_date'] > now:
                        return jsonify({'error': 'Mã giảm giá chưa có hiệu lực'}), 400
                    
                    if discount['end_date'] and discount['end_date'] < now:
                        return jsonify({'error': 'Mã giảm giá đã hết hạn'}), 400
                    
                    if discount['usage_limit'] and discount['used_count'] >= discount['usage_limit']:
                        return jsonify({'error': 'Mã giảm giá đã hết lượt sử dụng'}), 400
                    
                    # Convert to float
                    min_order_value = float(discount['min_order_value']) if discount['min_order_value'] else 0
                    
                    if subtotal < min_order_value:
                        return jsonify({
                            'error': f'Đơn hàng phải từ {min_order_value:,.0f}đ trở lên'
                        }), 400
                    
                    # Convert Decimal to float
                    discount_value = float(discount['discount_value'])
                    max_discount_amount = float(discount['max_discount_amount']) if discount['max_discount_amount'] else None
                    
                    # Calculate discount
                    if discount['discount_type'] == 'percentage':
                        discount_amount = subtotal * (discount_value / 100)
                        if max_discount_amount:
                            discount_amount = min(discount_amount, max_discount_amount)
                    else:  # fixed
                        discount_amount = discount_value
                    
                    discount_amount = min(discount_amount, subtotal)
                    discount_id = discount['id']
                
                total_amount = subtotal - discount_amount
                
                # Check stock
                for item in cart_items:
                    if item['quantity'] > item['stock_quantity']:
                        return jsonify({
                            'error': f'{item["name"]} không đủ hàng'
                        }), 400
                
                # Generate order number
                order_number = f"ORD{int(time.time())}"
                
                # Create order
                cur.execute("""
                    INSERT INTO orders (
                        user_id, order_number, subtotal, discount_amount, total_amount,
                        discount_code, shipping_address, phone, status, 
                        payment_status, payment_method
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING *
                """, (
                    current_user['id'], order_number, subtotal, discount_amount, total_amount,
                    discount_code if discount_code else None,
                    shipping_address, phone, 'pending', 'pending', payment_method
                ))
                
                order = dict(cur.fetchone())
                
                # ✅ Create order items WITH product_name and product_image
                for item in cart_items:
                    item_subtotal = float(item['price']) * item['quantity']
                    cur.execute("""
                        INSERT INTO order_items (
                            order_id, product_id, product_name, product_image,
                            quantity, price, subtotal
                        ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """, (
                        order['id'], 
                        item['product_id'], 
                        item['name'],              # product_name
                        item.get('image_url'),     # product_image
                        item['quantity'],
                        float(item['price']), 
                        item_subtotal
                    ))
                    
                    # Update stock
                    cur.execute("""
                        UPDATE products 
                        SET stock_quantity = stock_quantity - %s
                        WHERE id = %s
                    """, (item['quantity'], item['product_id']))
                
                # ✅ Create payment record (FIXED: payment_status)
                payment_code = f"PAY{int(time.time())}"
                
                cur.execute("""
                    INSERT INTO payments (
                        order_id, payment_code, payment_method, amount, payment_status
                    ) VALUES (%s, %s, %s, %s, %s)
                    RETURNING *
                """, (order['id'], payment_code, payment_method, total_amount, 'pending'))
                
                payment = dict(cur.fetchone())
                
                # TRACK DISCOUNT USAGE - FIXED VARIABLE NAMES
                if discount_id:
                    cur.execute("""
                        INSERT INTO discount_code_usage (
                            discount_code_id, user_id, order_id, discount_amount
                        ) VALUES (%s, %s, %s, %s)
                    """, (discount_id, current_user['id'], order['id'], discount_amount))
                    
                    # Increment used_count
                    cur.execute("""
                        UPDATE discount_codes 
                        SET used_count = used_count + 1
                        WHERE id = %s
                    """, (discount_id,))
                
                # Clear cart
                cur.execute("DELETE FROM cart WHERE user_id = %s", (current_user['id'],))
                
                conn.commit()
                
                return jsonify({
                    'message': 'Tạo đơn hàng thành công',
                    'order': order,
                    'payment': payment
                }), 201
                
    except Exception as e:
        print(f"[CREATE ORDER ERROR] {str(e)}")
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

## 2. Khởi tạo Thanh toán MoMo QR

@payment_bp.route('/initiate-momo-qr', methods=['POST'])
@token_required
def initiate_momo_qr(current_user):
    """Generate MoMo QR Code"""
    try:
        data = request.get_json()
        payment_code = data.get('payment_code')
        
        if not payment_code:
            return jsonify({'error': 'Thiếu mã thanh toán'}), 400
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Lấy thông tin payment
                cur.execute("""
                    SELECT p.*, o.order_number, o.total_amount
                    FROM payments p
                    JOIN orders o ON p.order_id = o.id
                    WHERE p.payment_code = %s
                """, (payment_code,))
                
                payment = cur.fetchone()
                
                if not payment:
                    return jsonify({'error': 'Thanh toán không tồn tại'}), 404
                
                # Tạo MoMo request
                order_id = payment_code # Dùng payment_code làm orderId
                amount = str(int(payment['amount']))
                order_info = f"Thanh toán đơn hàng {payment['order_number']}"
                request_id = f"{order_id}_{int(time.time())}"
                
                # Tạo signature
                raw_signature = (
                    f"accessKey={MOMO_ACCESS_KEY}"
                    f"&amount={amount}"
                    f"&extraData="
                    f"&ipnUrl={MOMO_NOTIFY_URL}"
                    f"&orderId={order_id}"
                    f"&orderInfo={order_info}"
                    f"&partnerCode={MOMO_PARTNER_CODE}"
                    f"&redirectUrl={MOMO_RETURN_URL}"
                    f"&requestId={request_id}"
                    f"&requestType=captureWallet"
                )
                
                signature = generate_momo_signature(raw_signature, MOMO_SECRET_KEY)
                
                payload = {
                    "partnerCode": MOMO_PARTNER_CODE,
                    "accessKey": MOMO_ACCESS_KEY,
                    "requestId": request_id,
                    "amount": amount,
                    "orderId": order_id,
                    "orderInfo": order_info,
                    "redirectUrl": MOMO_RETURN_URL,
                    "ipnUrl": MOMO_NOTIFY_URL,
                    "extraData": "",
                    "requestType": "captureWallet",
                    "signature": signature,
                    "lang": "vi"
                }
                
                print(f"[MOMO QR REQUEST] Initiating MoMo for {order_id}")
                
                response = requests.post(MOMO_ENDPOINT, json=payload, timeout=10)
                result = response.json()
                
                print(f"[MOMO QR RESPONSE] Result Code: {result.get('resultCode')}")
                
                if result.get('resultCode') == 0:
                    # ✅ GENERATE QR CODE IMAGE
                    qr_data = result.get('qrCodeUrl')
                    
                    if qr_data:
                        # Generate QR image
                        qr = qrcode.QRCode(version=1, box_size=10, border=5)
                        qr.add_data(qr_data)
                        qr.make(fit=True)
                        
                        img = qr.make_image(fill_color="black", back_color="white")
                        
                        # Convert to base64
                        buffer = io.BytesIO()
                        img.save(buffer, format='PNG')
                        img_str = base64.b64encode(buffer.getvalue()).decode()
                        
                        qr_image = f"data:image/png;base64,{img_str}"
                    else:
                        qr_image = None
                        
                    # Update payment record with QR/Deeplink info
                    cur.execute("""
                        UPDATE payments 
                        SET transaction_id = %s, 
                            qr_code_url = %s, 
                            deep_link = %s
                        WHERE payment_code = %s
                    """, (
                        request_id,
                        result.get('qrCodeUrl'),
                        result.get('deeplink'),
                        payment_code
                    ))
                    conn.commit()
                    
                    return jsonify({
                        'message': 'Tạo mã QR thành công',
                        'qr_code_image': qr_image,
                        'qr_code_url': result.get('qrCodeUrl'),
                        'deep_link': result.get('deeplink'),
                        'payment_url': result.get('payUrl'),
                        'order_number': payment['order_number'],
                        'amount': float(payment['amount'])
                    }), 200
                else:
                    return jsonify({
                        'error': result.get('message', 'Tạo mã QR thất bại'),
                        'result_code': result.get('resultCode')
                    }), 400
                    
    except requests.exceptions.RequestException as e:
        print(f"[MOMO QR ERROR] Connection error: {str(e)}")
        return jsonify({'error': f'Lỗi kết nối: {str(e)}'}), 500
    except Exception as e:
        print(f"[MOMO QR ERROR] {str(e)}")
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

## 3. MoMo Return URL (Client Redirect)

@payment_bp.route('/momo-return', methods=['GET'])
def momo_return_url():
    """Xử lý redirect từ MoMo sau khi người dùng thanh toán"""
    
    # Lấy parameters từ URL
    params = request.args.to_dict()
    order_id = params.get('orderId') 
    result_code = params.get('resultCode')
    message = params.get('message')
    signature = params.get('signature')
    
    # Chuẩn bị raw signature để Verify
    raw_signature = (
        f"accessKey={MOMO_ACCESS_KEY}"
        f"&amount={params.get('amount')}"
        f"&extraData={params.get('extraData', '')}"
        f"&message={message}"
        f"&orderId={order_id}"
        f"&orderInfo={params.get('orderInfo')}"
        f"&orderType={params.get('orderType')}"
        f"&partnerCode={MOMO_PARTNER_CODE}"
        f"&payType={params.get('payType')}"
        f"&requestId={params.get('requestId')}"
        f"&responseTime={params.get('responseTime')}"
        f"&resultCode={result_code}"
        f"&transId={params.get('transId')}"
    )
    
    expected_signature = generate_momo_signature(raw_signature, MOMO_SECRET_KEY)
    
    print(f"[MOMO RETURN] Order ID: {order_id}, Result: {result_code}")
    
    if signature != expected_signature:
        print("[MOMO RETURN ERROR] Signature mismatch!")
        return redirect(f'{FRONTEND_URL}/payment/failed?msg=Invalid signature')
    
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Tìm payment
                cur.execute("SELECT * FROM payments WHERE payment_code = %s", (order_id,))
                payment = cur.fetchone()
                
                if not payment:
                    return redirect(f'{FRONTEND_URL}/payment/failed?msg=Payment not found')

                # Cập nhật database
                if result_code == '0':
                    # Thành công - ✅ FIXED: payment_status
                    cur.execute("""
                        UPDATE payments
                        SET payment_status = 'completed',
                            payment_date = NOW(),
                            transaction_id = %s
                        WHERE payment_code = %s AND payment_status != 'completed'
                    """, (params.get('transId'), order_id))
                    
                    # Cập nhật order status
                    cur.execute("""
                        UPDATE orders
                        SET payment_status = 'paid',
                            status = 'confirmed'
                        WHERE id = %s AND payment_status != 'paid'
                    """, (payment['order_id'],))
                    
                    conn.commit()
                    print(f"[MOMO RETURN SUCCESS] Order {order_id} confirmed.")
                    return redirect(f'{FRONTEND_URL}/payment/success?order_id={payment["order_id"]}&pay_code={order_id}')
                else:
                    # Thất bại - ✅ FIXED: payment_status
                    cur.execute("""
                        UPDATE payments
                        SET payment_status = 'failed'
                        WHERE payment_code = %s AND payment_status != 'completed'
                    """, (order_id,))
                    conn.commit()
                    print(f"[MOMO RETURN FAILED] Order {order_id} failed. Message: {message}")
                    return redirect(f'{FRONTEND_URL}/payment/failed?msg={message}')
            
    except Exception as e:
        print(f"[MOMO RETURN ERROR] Callback DB error: {str(e)}")
        traceback.print_exc()
        return redirect(f'{FRONTEND_URL}/payment/failed?msg=System error during update')

## 4. MoMo IPN (Instant Payment Notification - Server-to-Server)

@payment_bp.route('/momo-notify', methods=['POST'])
def momo_notify_url():
    """Xử lý IPN (Instant Payment Notification) từ MoMo"""
    
    data = request.get_json()
    
    print("=" * 60)
    print("[MOMO IPN RECEIVED]")
    print(json.dumps(data, indent=2))
    print("=" * 60)
    
    try:
        order_id = data.get('orderId')
        result_code = str(data.get('resultCode'))
        
        # Tạo raw signature để Verify
        raw_signature = (
            f"accessKey={MOMO_ACCESS_KEY}"
            f"&amount={data.get('amount')}"
            f"&extraData={data.get('extraData', '')}"
            f"&message={data.get('message')}"
            f"&orderId={order_id}"
            f"&orderInfo={data.get('orderInfo')}"
            f"&orderType={data.get('orderType')}"
            f"&partnerCode={MOMO_PARTNER_CODE}"
            f"&payType={data.get('payType')}"
            f"&requestId={data.get('requestId')}"
            f"&responseTime={data.get('responseTime')}"
            f"&resultCode={result_code}"
            f"&transId={data.get('transId')}"
        )
        
        expected_signature = generate_momo_signature(raw_signature, MOMO_SECRET_KEY)
        received_signature = data.get('signature')
        
        if received_signature != expected_signature:
            print("[IPN ERROR] Invalid signature")
            # MoMo yêu cầu trả về resultCode=97 nếu signature không hợp lệ
            return jsonify({'resultCode': 97, 'message': 'Invalid signature'}), 200
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                # Tìm payment
                cur.execute("SELECT * FROM payments WHERE payment_code = %s", (order_id,))
                payment = cur.fetchone()
                
                if not payment:
                    print(f"[IPN ERROR] Payment not found: {order_id}")
                    # MoMo yêu cầu trả về resultCode=99 nếu không tìm thấy
                    return jsonify({'resultCode': 99, 'message': 'Payment not found'}), 200
                
                # ✅ FIXED: payment_status
                if payment['payment_status'] == 'completed':
                    print(f"[IPN INFO] Payment {order_id} already completed.")
                    # Đã hoàn tất, trả về thành công để MoMo ngừng gửi
                    return jsonify({'resultCode': 0, 'message': 'Success'}), 200

                if result_code == '0':
                    # Thanh toán thành công - ✅ FIXED: payment_status
                    cur.execute("""
                        UPDATE payments
                        SET payment_status = 'completed',
                            payment_date = NOW(),
                            transaction_id = %s
                        WHERE payment_code = %s
                    """, (data.get('transId'), order_id))
                    
                    # Cập nhật order status
                    cur.execute("""
                        UPDATE orders
                        SET payment_status = 'paid',
                            status = 'confirmed'
                        WHERE id = %s
                    """, (payment['order_id'],))
                    
                    conn.commit()
                    print(f"[IPN SUCCESS] ✅ Payment completed via IPN: {order_id}")
                    # Trả về thành công
                    return jsonify({'resultCode': 0, 'message': 'Success'}), 200
                else:
                    # Thanh toán thất bại - ✅ FIXED: payment_status
                    cur.execute("""
                        UPDATE payments
                        SET payment_status = 'failed'
                        WHERE payment_code = %s
                    """, (order_id,))
                    conn.commit()
                    print(f"[IPN FAILED] ❌ Payment failed: {order_id}, Result: {result_code}")
                    # MoMo yêu cầu trả về resultCode=0 dù thất bại hay thành công (miễn là nhận được)
                    return jsonify({'resultCode': 0, 'message': 'Confirmed'}), 200
                    
    except Exception as e:
        print(f"[IPN ERROR] System error: {str(e)}")
        traceback.print_exc()
        # Trả về System Error
        return jsonify({'resultCode': 99, 'message': 'System error'}), 200

## 5. Check Payment Status

@payment_bp.route('/check-momo-status/<payment_code>', methods=['GET'])
@token_required
def check_momo_status(current_user, payment_code):
    """Kiểm tra trạng thái thanh toán"""
    try:
        user_id = current_user['id']
        
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("""
                    SELECT 
                        p.*,
                        o.order_number,
                        o.total_amount as order_total
                    FROM payments p
                    JOIN orders o ON p.order_id = o.id
                    WHERE p.payment_code = %s AND o.user_id = %s
                """, (payment_code, user_id))
                
                payment = cur.fetchone()
                
                if not payment:
                    return jsonify({'error': 'Payment không tồn tại hoặc không thuộc sở hữu của bạn'}), 404
                
                # ✅ FIXED: payment_status
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
        print(f"[CHECK STATUS ERROR] {str(e)}")
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500