# backend/app/utils/cloudinary_helper.py
import cloudinary
import cloudinary.uploader
from app.config import Config

cloudinary.config(
    cloud_name=Config.CLOUDINARY_CLOUD_NAME,
    api_key=Config.CLOUDINARY_API_KEY,
    api_secret=Config.CLOUDINARY_API_SECRET
)

def upload_image(file, folder="ecommerce"):
    """Upload ảnh lên Cloudinary"""
    try:
        result = cloudinary.uploader.upload(
            file,
            folder=folder,
            resource_type="image"
        )
        return result['secure_url']
    except Exception as e:
        raise Exception(f"Lỗi upload ảnh: {str(e)}")

def delete_image(public_id):
    """Xóa ảnh từ Cloudinary"""
    try:
        cloudinary.uploader.destroy(public_id)
    except Exception as e:
        print(f"Lỗi xóa ảnh: {str(e)}")