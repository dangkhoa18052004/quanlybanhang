# backend/run.py
from app import create_app
from dotenv import load_dotenv
import os
# Load environment variables
load_dotenv()

app = create_app()
print("="*80)
print("ENVIRONMENT VARIABLES CHECK:")
print(f"DATABASE_URL: {os.getenv('DATABASE_URL', 'NOT SET')}")
print(f"JWT_SECRET_KEY: {os.getenv('JWT_SECRET_KEY', 'NOT SET')}")
print("="*80)

if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )