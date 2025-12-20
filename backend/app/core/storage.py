from google.cloud import storage
from app.core.config import settings
from fastapi import UploadFile, HTTPException
import uuid
import logging

class StorageService:
    @staticmethod
    async def upload_file(file: UploadFile, folder: str = "uploads") -> str:
        """
        Uploads a file to Google Cloud Storage and returns the public URL.
        """
        bucket_name = settings.GCS_BUCKET_NAME
        
        if not bucket_name:
             logging.warning("GCS_BUCKET_NAME not set. Skipping upload.")
             # For dev without GCS, maybe return a dummy URL or error
             raise HTTPException(status_code=500, detail="Storage configuration missing")

        try:
            storage_client = storage.Client()
            bucket = storage_client.bucket(bucket_name)
            
            # Generate unique filename
            extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
            filename = f"{folder}/{uuid.uuid4()}.{extension}"
            
            blob = bucket.blob(filename)
            
            # Upload file
            blob.upload_from_file(file.file, content_type=file.content_type)
            
            # Make public (optional, depends on bucket policy. Usually fine for profile pics)
            # blob.make_public() 
            
            # Return public URL
            return blob.public_url
            
        except Exception as e:
            logging.error(f"Failed to upload file to GCS: {e}")
            raise HTTPException(status_code=500, detail=f"File upload failed: {str(e)}")
