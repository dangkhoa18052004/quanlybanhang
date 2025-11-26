-- -- database_schema.sql

-- -- Bảng Users
-- CREATE TABLE users (
--     id SERIAL PRIMARY KEY,
--     email VARCHAR(255) UNIQUE NOT NULL,
--     password_hash VARCHAR(255) NOT NULL,
--     full_name VARCHAR(255) NOT NULL,
--     phone VARCHAR(20),
--     address TEXT,
--     role VARCHAR(20) DEFAULT 'customer', -- 'customer' or 'admin'
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- -- Bảng Categories
-- CREATE TABLE categories (
--     id SERIAL PRIMARY KEY,
--     name VARCHAR(100) NOT NULL,
--     description TEXT,
--     image_url VARCHAR(500)
-- );

-- -- Bảng Products
-- CREATE TABLE products (
--     id SERIAL PRIMARY KEY,
--     name VARCHAR(255) NOT NULL,
--     description TEXT,
--     price DECIMAL(10, 2) NOT NULL,
--     stock_quantity INTEGER DEFAULT 0,
--     category_id INTEGER REFERENCES categories(id),
--     image_url VARCHAR(500),
--     average_rating DECIMAL(2, 1) DEFAULT 0.0,
--     total_reviews INTEGER DEFAULT 0,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- -- Bảng Product Images (nhiều ảnh cho 1 sản phẩm)
-- CREATE TABLE product_images (
--     id SERIAL PRIMARY KEY,
--     product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
--     image_url VARCHAR(500) NOT NULL,
--     is_primary BOOLEAN DEFAULT FALSE
-- );

-- -- Bảng Cart
-- CREATE TABLE cart (
--     id SERIAL PRIMARY KEY,
--     user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
--     product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
--     quantity INTEGER NOT NULL,
--     added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     UNIQUE(user_id, product_id)
-- );

-- -- Bảng Discount Codes
-- CREATE TABLE discount_codes (
--     id SERIAL PRIMARY KEY,
--     code VARCHAR(50) UNIQUE NOT NULL,
--     discount_percent INTEGER NOT NULL, -- 10 = 10%
--     min_order_value DECIMAL(10, 2) DEFAULT 0,
--     max_discount DECIMAL(10, 2),
--     valid_from TIMESTAMP,
--     valid_until TIMESTAMP,
--     usage_limit INTEGER,
--     used_count INTEGER DEFAULT 0,
--     is_active BOOLEAN DEFAULT TRUE
-- );

-- -- Bảng Orders
-- CREATE TABLE orders (
--     id SERIAL PRIMARY KEY,
--     user_id INTEGER REFERENCES users(id),
--     order_number VARCHAR(50) UNIQUE NOT NULL,
--     subtotal DECIMAL(10, 2) NOT NULL,
--     discount_amount DECIMAL(10, 2) DEFAULT 0,
--     total_amount DECIMAL(10, 2) NOT NULL,
--     discount_code VARCHAR(50),
--     shipping_address TEXT NOT NULL,
--     phone VARCHAR(20) NOT NULL,
--     status VARCHAR(50) DEFAULT 'pending', -- pending, paid, shipping, delivered, cancelled
--     payment_method VARCHAR(50), -- momo, vnpay, cod
--     payment_status VARCHAR(50) DEFAULT 'pending', -- pending, paid, failed
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- -- Bảng Order Items
-- CREATE TABLE order_items (
--     id SERIAL PRIMARY KEY,
--     order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
--     product_id INTEGER REFERENCES products(id),
--     product_name VARCHAR(255) NOT NULL,
--     product_image VARCHAR(500),
--     price DECIMAL(10, 2) NOT NULL,
--     quantity INTEGER NOT NULL,
--     subtotal DECIMAL(10, 2) NOT NULL
-- );

-- -- Bảng Reviews
-- CREATE TABLE reviews (
--     id SERIAL PRIMARY KEY,
--     user_id INTEGER REFERENCES users(id),
--     product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
--     order_id INTEGER REFERENCES orders(id),
--     rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
--     comment TEXT,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     UNIQUE(user_id, product_id, order_id)
-- );

-- -- Index để tối ưu performance
-- CREATE INDEX idx_products_category ON products(category_id);
-- CREATE INDEX idx_cart_user ON cart(user_id);
-- CREATE INDEX idx_orders_user ON orders(user_id);
-- CREATE INDEX idx_reviews_product ON reviews(product_id);
-- CREATE TABLE payments (
--     id SERIAL PRIMARY KEY,
--     payment_code VARCHAR(50) UNIQUE NOT NULL,
--     order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
--     user_id INTEGER REFERENCES users(id),
--     amount DECIMAL(10, 2) NOT NULL,
--     payment_method VARCHAR(50) NOT NULL, -- momo, vnpay, cod
--     payment_status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
--     transaction_id VARCHAR(255),
--     payment_date TIMESTAMP,
--     description TEXT,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- CREATE INDEX idx_payments_order ON payments(order_id);
-- CREATE INDEX idx_payments_user ON payments(user_id);
-- CREATE INDEX idx_payments_code ON payments(payment_code);

-- Thêm vào database
-- ALTER TABLE users ADD COLUMN avatar_url VARCHAR(500);


-- CREATE TABLE IF NOT EXISTS discount_codes (
--     id SERIAL PRIMARY KEY,
--     code VARCHAR(50) UNIQUE NOT NULL,
--     description TEXT,
--     discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
--     discount_value DECIMAL(10, 2) NOT NULL,
--     min_order_value DECIMAL(10, 2) DEFAULT 0,
--     max_discount_amount DECIMAL(10, 2),
--     usage_limit INTEGER,
--     used_count INTEGER DEFAULT 0,
--     start_date TIMESTAMP,
--     end_date TIMESTAMP,
--     is_active BOOLEAN DEFAULT TRUE,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- -- Indexes
-- CREATE INDEX idx_discount_codes_code ON discount_codes(code);
-- CREATE INDEX idx_discount_codes_is_active ON discount_codes(is_active);
-- CREATE INDEX idx_discount_codes_dates ON discount_codes(start_date, end_date);

-- -- ============================================================
-- -- DISCOUNT CODE USAGE TRACKING
-- -- ============================================================

-- CREATE TABLE IF NOT EXISTS discount_code_usage (
--     id SERIAL PRIMARY KEY,
--     discount_code_id INTEGER REFERENCES discount_codes(id) ON DELETE CASCADE,
--     user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
--     order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
--     discount_amount DECIMAL(10, 2) NOT NULL,
--     used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     UNIQUE(discount_code_id, order_id)
-- );

-- -- Indexes
-- CREATE INDEX idx_discount_usage_user ON discount_code_usage(user_id);
-- CREATE INDEX idx_discount_usage_code ON discount_code_usage(discount_code_id);

-- -- ============================================================
-- -- UPDATE PAYMENTS TABLE FOR QR CODE
-- -- ============================================================

-- -- Add QR code fields to payments table
-- ALTER TABLE payments 
-- ADD COLUMN IF NOT EXISTS qr_code_url TEXT,
-- ADD COLUMN IF NOT EXISTS qr_data TEXT,
-- ADD COLUMN IF NOT EXISTS deep_link TEXT;

-- -- ============================================================
-- -- SAMPLE DISCOUNT CODES
-- -- ============================================================

-- INSERT INTO discount_codes (
--     code, description, discount_type, discount_value, 
--     min_order_value, max_discount_amount, usage_limit, 
--     start_date, end_date, is_active
-- ) VALUES
-- -- 10% off for orders over 100k
-- ('WELCOME10', 'Giảm 10% cho đơn hàng đầu tiên', 'percentage', 10.00, 
--  100000, 50000, 100, NOW(), NOW() + INTERVAL '30 days', TRUE),

-- -- 50k off for orders over 500k
-- ('SAVE50K', 'Giảm 50.000đ cho đơn từ 500.000đ', 'fixed', 50000, 
--  500000, NULL, 200, NOW(), NOW() + INTERVAL '30 days', TRUE),

-- -- 20% off for orders over 1M
-- ('MEGA20', 'Giảm 20% cho đơn từ 1.000.000đ', 'percentage', 20.00, 
--  1000000, 200000, 50, NOW(), NOW() + INTERVAL '30 days', TRUE),

-- -- Free shipping (100k fixed discount)
-- ('FREESHIP', 'Miễn phí vận chuyển', 'fixed', 100000, 
--  0, 100000, NULL, NOW(), NOW() + INTERVAL '60 days', TRUE),

-- -- Flash sale 30% (limited time)
-- ('FLASH30', 'Flash Sale - Giảm 30%', 'percentage', 30.00, 
--  200000, 300000, 20, NOW(), NOW() + INTERVAL '7 days', TRUE)
-- ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- UPDATE TRIGGER FOR updated_at
-- ============================================================

-- CREATE OR REPLACE FUNCTION update_discount_codes_updated_at()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     NEW.updated_at = CURRENT_TIMESTAMP;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_update_discount_codes_updated_at
-- BEFORE UPDATE ON discount_codes
-- FOR EACH ROW
-- EXECUTE FUNCTION update_discount_codes_updated_at();

-- -- ============================================================
-- -- VIEWS FOR EASY QUERYING
-- -- ============================================================

-- -- Active discount codes view
-- CREATE OR REPLACE VIEW active_discount_codes AS
-- SELECT 
--     id, code, description, discount_type, discount_value,
--     min_order_value, max_discount_amount, usage_limit, used_count,
--     start_date, end_date,
--     CASE 
--         WHEN usage_limit IS NOT NULL AND used_count >= usage_limit THEN FALSE
--         WHEN end_date IS NOT NULL AND end_date < NOW() THEN FALSE
--         WHEN start_date IS NOT NULL AND start_date > NOW() THEN FALSE
--         ELSE TRUE
--     END as is_currently_valid
-- FROM discount_codes
-- WHERE is_active = TRUE;

-- -- Discount usage statistics
-- CREATE OR REPLACE VIEW discount_usage_stats AS
-- SELECT 
--     dc.id,
--     dc.code,
--     dc.description,
--     dc.used_count,
--     dc.usage_limit,
--     COUNT(dcu.id) as total_uses,
--     SUM(dcu.discount_amount) as total_discount_given,
--     COUNT(DISTINCT dcu.user_id) as unique_users
-- FROM discount_codes dc
-- LEFT JOIN discount_code_usage dcu ON dc.id = dcu.discount_code_id
-- GROUP BY dc.id, dc.code, dc.description, dc.used_count, dc.usage_limit;

-- ALTER TABLE payments ADD COLUMN qr_code_url TEXT;
-- ALTER TABLE payments ADD COLUMN qr_data TEXT;
-- ALTER TABLE payments ADD COLUMN deep_link TEXT;
-- ALTER TABLE payments ADD COLUMN transaction_id TEXT;

-- Tạo bảng discount_code_usage nếu chưa tồn tại
CREATE TABLE IF NOT EXISTS discount_code_usage (
    id SERIAL PRIMARY KEY,
    discount_code_id INTEGER REFERENCES discount_codes(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    discount_amount DECIMAL(10, 2) NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(discount_code_id, order_id)
);

-- Tạo indexes cho bảng discount_code_usage
CREATE INDEX IF NOT EXISTS idx_discount_usage_user ON discount_code_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_discount_usage_code ON discount_code_usage(discount_code_id);
CREATE INDEX IF NOT EXISTS idx_discount_usage_order ON discount_code_usage(order_id);

-- Tạo hoặc thay thế view active_discount_codes
CREATE OR REPLACE VIEW active_discount_codes AS
SELECT 
    dc.id,
    dc.code,
    dc.description,
    dc.discount_type,
    dc.discount_value,
    dc.min_order_value,
    dc.max_discount_amount,
    dc.usage_limit,
    dc.used_count,
    dc.start_date,
    dc.end_date,
    dc.is_active,
    dc.created_at,
    dc.updated_at,
    CASE 
        WHEN dc.usage_limit IS NOT NULL AND dc.used_count >= dc.usage_limit THEN FALSE
        WHEN dc.end_date IS NOT NULL AND dc.end_date < NOW() THEN FALSE
        WHEN dc.start_date IS NOT NULL AND dc.start_date > NOW() THEN FALSE
        ELSE dc.is_active
    END as is_currently_valid
FROM discount_codes dc
WHERE dc.is_active = TRUE;