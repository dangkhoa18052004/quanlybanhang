# backend/app/utils/simple_image_helper.py
import io
from PIL import Image

def process_image_for_db(image_file):
    """
    Xử lý ảnh và trả về binary data để lưu vào database
    
    Args:
        image_file: File upload từ request.files
    
    Returns:
        tuple: (image_data: bytes, content_type: str)
    """
    try:
        # Đọc ảnh
        img = Image.open(image_file)
        
        # Resize nếu quá lớn (max 1200px để tiết kiệm dung lượng)
        max_size = (1200, 1200)
        img.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        # Convert sang RGB nếu là PNG với alpha channel
        if img.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            if img.mode == 'RGBA':
                background.paste(img, mask=img.split()[-1])
            else:
                background.paste(img)
            img = background
        
        # Convert sang JPEG và lưu vào BytesIO
        output = io.BytesIO()
        img.save(output, format='JPEG', quality=85, optimize=True)
        image_data = output.getvalue()
        
        print(f"[IMAGE PROCESSED] Size: {len(image_data)} bytes")
        
        return image_data, 'image/jpeg'
    
    except Exception as e:
        print(f"[IMAGE PROCESS ERROR] {str(e)}")
        raise Exception(f'Lỗi xử lý ảnh: {str(e)}')