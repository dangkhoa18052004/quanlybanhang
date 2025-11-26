# backend/app/utils/upload_helper.py
import os
from werkzeug.utils import secure_filename
from datetime import datetime
import uuid

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.dirname(__file__)), '..', 'uploads')

def allowed_file(filename):
    """Kiểm tra file có hợp lệ không"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def save_upload_file(file, folder='products'):
    """
    Lưu file upload vào thư mục local
    
    Args:
        file: FileStorage object từ request.files
        folder: Tên thư mục con (products, categories, users...)
    
    Returns:
        str: Đường dẫn file (VD: /uploads/products/20241126_abc123.jpg)
    """
    try:
        if not file or file.filename == '':
            raise ValueError('Không có file được chọn')
        
        if not allowed_file(file.filename):
            raise ValueError('Định dạng file không hợp lệ')
        
        filename = secure_filename(file.filename)
        file_ext = filename.rsplit('.', 1)[1].lower()
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_id = str(uuid.uuid4())[:8]
        new_filename = f"{timestamp}_{unique_id}.{file_ext}"
        
        upload_path = os.path.join(UPLOAD_FOLDER, folder)
        os.makedirs(upload_path, exist_ok=True)
        
        file_path = os.path.join(upload_path, new_filename)
        file.save(file_path)
        
        relative_path = f'/uploads/{folder}/{new_filename}'
        
        print(f"[UPLOAD] ✅ Saved: {relative_path}")
        
        return relative_path
        
    except Exception as e:
        print(f"[UPLOAD ERROR] {str(e)}")
        raise e

def delete_upload_file(file_path):
    """Xóa file đã upload"""
    try:
        if not file_path:
            return
        
        full_path = os.path.join(
            os.path.dirname(os.path.dirname(__file__)), 
            '..',
            file_path.lstrip('/')
        )
        
        if os.path.exists(full_path):
            os.remove(full_path)
            print(f"[DELETE] ✅ Deleted: {file_path}")
        
    except Exception as e:
        print(f"[DELETE ERROR] {str(e)}")