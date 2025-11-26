# backend/seed_data.py
import psycopg2
from werkzeug.security import generate_password_hash

conn = psycopg2.connect(
    dbname="flutter",
    user="postgres",
    password="13579",
    host="localhost"
)
cur = conn.cursor()

# 1. Tạo categories
categories = [
    ('Điện thoại', 'Điện thoại thông minh', None),
    ('Laptop', 'Máy tính xách tay', None),
    ('Phụ kiện', 'Phụ kiện điện tử', None),
]

for cat in categories:
    cur.execute("""
        INSERT INTO categories (name, description, image_url)
        VALUES (%s, %s, %s)
        ON CONFLICT DO NOTHING
    """, cat)

# 2. Tạo products
products = [
    ('iPhone 15 Pro Max', 'iPhone mới nhất', 29990000, 50, 1, '/uploads/iphone15.jpg'),
    ('MacBook Pro M3', 'Laptop Apple M3', 45990000, 30, 2, '/uploads/macbook.jpg'),
    ('AirPods Pro 2', 'Tai nghe không dây', 6990000, 100, 3, '/uploads/airpods.jpg'),
]

for prod in products:
    cur.execute("""
        INSERT INTO products (name, description, price, stock_quantity, category_id, image_url)
        VALUES (%s, %s, %s, %s, %s, %s)
        ON CONFLICT DO NOTHING
    """, prod)

conn.commit()
cur.close()
conn.close()

print("✅ Seed data created!")