# app/utils/db.py
"""
Database connection utilities for PostgreSQL
"""
import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
import os
from dotenv import load_dotenv

load_dotenv()

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'flutter'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'postgres')
}


@contextmanager
def get_db_connection():
    """
    Context manager for database connection
    
    Usage:
        with get_db_connection() as conn:
            # use conn
    """
    conn = None
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        yield conn
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"[DB CONNECTION ERROR] {str(e)}")
        raise
    finally:
        if conn:
            conn.close()


@contextmanager
def get_db_cursor(conn):
    """
    Context manager for database cursor with RealDictCursor
    Returns rows as dictionaries
    
    Usage:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("SELECT * FROM users")
                users = cur.fetchall()
    """
    cur = None
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        yield cur
    except Exception as e:
        print(f"[DB CURSOR ERROR] {str(e)}")
        raise
    finally:
        if cur:
            cur.close()


def execute_query(query, params=None, fetch=True):
    """
    Execute a single query and return results
    
    Args:
        query (str): SQL query
        params (tuple): Query parameters
        fetch (bool): Whether to fetch results
    
    Returns:
        list: Query results if fetch=True, None otherwise
    """
    with get_db_connection() as conn:
        with get_db_cursor(conn) as cur:
            cur.execute(query, params or ())
            
            if fetch:
                return cur.fetchall()
            else:
                conn.commit()
                return None


def execute_many(query, params_list):
    """
    Execute query with multiple parameter sets
    
    Args:
        query (str): SQL query
        params_list (list): List of parameter tuples
    """
    with get_db_connection() as conn:
        with get_db_cursor(conn) as cur:
            cur.executemany(query, params_list)
            conn.commit()


# Test connection
if __name__ == "__main__":
    try:
        with get_db_connection() as conn:
            with get_db_cursor(conn) as cur:
                cur.execute("SELECT version();")
                version = cur.fetchone()
                print(f"✅ Database connected successfully!")
                print(f"PostgreSQL version: {version['version']}")
    except Exception as e:
        print(f"❌ Database connection failed: {e}")