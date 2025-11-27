import bcrypt
import psycopg2
from app.models import get_db_connection, get_db_cursor

def create_admin():
    email = input("Admin email: ")
    password = input("Admin password: ")
    full_name = input("Admin full name: ")
    
    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    with get_db_connection() as conn:
        with get_db_cursor(conn) as cur:
            cur.execute("""
                INSERT INTO users (email, password_hash, full_name, role)
                VALUES (%s, %s, %s, 'admin')
                RETURNING id, email, full_name, role
            """, (email, password_hash, full_name))
            
            admin = cur.fetchone()
            print(f"✅ Admin created: {admin}")

if __name__ == "__main__":
    create_admin()