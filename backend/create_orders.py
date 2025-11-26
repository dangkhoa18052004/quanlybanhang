# backend/create_orders.py
import psycopg2
import os
from datetime import datetime

DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:13579@localhost:5432/flutter')

def create_sample_orders():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    try:
        # Lấy user_id
        cur.execute("SELECT id FROM users WHERE email = 'khoa@gmail.com'")
        user = cur.fetchone()
        
        if not user:
            print("❌ User không tồn tại")
            return
            
        user_id = user[0]
        
        # Tạo orders mẫu
        orders_data = [
            {
                'order_number': 'ORD001',
                'subtotal': 22990000,
                'discount': 0,
                'total': 22990000,
                'status': 'pending',
                'payment_status': 'pending',
                'payment_method': 'cod',
                'address': '123 Đường ABC, Quận 1, TP.HCM',
                'phone': '0387829152'
            },
            {
                'order_number': 'ORD002', 
                'subtotal': 42990000,
                'discount': 2000000,
                'total': 40990000,
                'status': 'confirmed',
                'payment_status': 'paid',
                'payment_method': 'momo',
                'address': '456 Đường XYZ, Quận 2, TP.HCM',
                'phone': '0387829152'
            }
        ]
        
        for order_data in orders_data:
            cur.execute("""
                INSERT INTO orders (user_id, order_number, subtotal, discount_amount, total_amount, 
                                  status, payment_status, payment_method, shipping_address, phone, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (user_id, order_data['order_number'], order_data['subtotal'], 
                  order_data['discount'], order_data['total'], order_data['status'],
                  order_data['payment_status'], order_data['payment_method'],
                  order_data['address'], order_data['phone'], datetime.now()))
            
            order_id = cur.fetchone()[0]
            print(f"✅ Created order: {order_data['order_number']}")
        
        conn.commit()
        print("✅ Sample orders created successfully!")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    create_sample_orders()