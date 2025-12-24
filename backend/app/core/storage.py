from google.cloud import storage
from google.oauth2 import service_account
from app.core.config import settings
from fastapi import UploadFile, HTTPException
import uuid
import logging
import os

class StorageService:
    _client = None
    
    @classmethod
    def _get_client(cls):
        """Get or create a storage client with proper credentials."""
        if cls._client is not None:
            return cls._client
            
        try:
            # On Cloud Run, default credentials automatically use the attached service account
            # This is the simplest and most secure approach
            cls._client = storage.Client()
            logging.info("Using default GCP credentials (Cloud Run service account)")
            return cls._client
            
        except Exception as e:
            logging.warning(f"Default credentials failed: {e}, trying local file...")
            
            # Fallback: Check for local credentials file (for local development)
            local_creds = os.path.join(os.path.dirname(__file__), '../../firebase_credentials.json')
            if os.path.exists(local_creds):
                try:
                    credentials = service_account.Credentials.from_service_account_file(local_creds)
                    cls._client = storage.Client(credentials=credentials)
                    logging.info("Using local firebase_credentials.json")
                    return cls._client
                except Exception as e2:
                    logging.error(f"Local credentials also failed: {e2}")
            
            raise Exception(f"Could not initialize storage client: {e}")

    @staticmethod
    async def upload_file(file: UploadFile, folder: str = "uploads") -> str:
        """
        Uploads a file to Google Cloud Storage and returns the public URL.
        """
        bucket_name = settings.GCS_BUCKET_NAME
        
        if not bucket_name:
             logging.warning("GCS_BUCKET_NAME not set. Skipping upload.")
             raise HTTPException(status_code=500, detail="Storage configuration missing: GCS_BUCKET_NAME not set")

        try:
            storage_client = StorageService._get_client()
            bucket = storage_client.bucket(bucket_name)
            
            # Generate unique filename
            extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
            filename = f"{folder}/{uuid.uuid4()}.{extension}"
            
            blob = bucket.blob(filename)
            
            # Upload file
            blob.upload_from_file(file.file, content_type=file.content_type)
            
            # Return public URL
            return blob.public_url
            
        except Exception as e:
            logging.error(f"Failed to upload file to GCS: {e}")
            raise HTTPException(status_code=500, detail=f"File upload failed: {str(e)}")


