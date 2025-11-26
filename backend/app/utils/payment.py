# backend/app/utils/payment.py
import hashlib
import hmac
import json
import requests
from app.config import Config

def create_momo_payment(order_id, amount, order_info):
    """Tạo request thanh toán MoMo"""
    
    endpoint = Config.MOMO_ENDPOINT
    partner_code = Config.MOMO_PARTNER_CODE
    access_key = Config.MOMO_ACCESS_KEY
    secret_key = Config.MOMO_SECRET_KEY
    redirect_url = Config.MOMO_REDIRECT_URL
    ipn_url = Config.MOMO_IPN_URL
    
    request_id = f"REQ_{order_id}"
    order_id_str = str(order_id)
    amount_str = str(int(amount))
    
    # Tạo raw signature
    raw_signature = f"accessKey={access_key}&amount={amount_str}&extraData=&ipnUrl={ipn_url}&orderId={order_id_str}&orderInfo={order_info}&partnerCode={partner_code}&redirectUrl={redirect_url}&requestId={request_id}&requestType=captureWallet"
    
    # Tạo signature
    signature = hmac.new(
        secret_key.encode('utf-8'),
        raw_signature.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    # Request body
    data = {
        'partnerCode': partner_code,
        'accessKey': access_key,
        'requestId': request_id,
        'amount': amount_str,
        'orderId': order_id_str,
        'orderInfo': order_info,
        'redirectUrl': redirect_url,
        'ipnUrl': ipn_url,
        'extraData': '',
        'requestType': 'captureWallet',
        'signature': signature,
        'lang': 'vi'
    }
    
    try:
        response = requests.post(endpoint, json=data, timeout=10)
        return response.json()
    except Exception as e:
        return {'resultCode': -1, 'message': str(e)}

def verify_momo_signature(data, signature):
    """Xác thực signature từ MoMo IPN"""
    secret_key = Config.MOMO_SECRET_KEY
    
    raw_signature = f"accessKey={data.get('accessKey')}&amount={data.get('amount')}&extraData={data.get('extraData')}&message={data.get('message')}&orderId={data.get('orderId')}&orderInfo={data.get('orderInfo')}&orderType={data.get('orderType')}&partnerCode={data.get('partnerCode')}&payType={data.get('payType')}&requestId={data.get('requestId')}&responseTime={data.get('responseTime')}&resultCode={data.get('resultCode')}&transId={data.get('transId')}"
    
    expected_signature = hmac.new(
        secret_key.encode('utf-8'),
        raw_signature.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    return signature == expected_signature