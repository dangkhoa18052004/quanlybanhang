# backend/app/models.py
import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
import os

DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:13579@localhost:5432/flutter')

@contextmanager
def get_db_connection():
    """Context manager cho database connection"""
    conn = psycopg2.connect(DATABASE_URL)
    try:
        yield conn
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()

def get_db_cursor(conn):
    """Lấy cursor với RealDictCursor"""
    return conn.cursor(cursor_factory=RealDictCursor)