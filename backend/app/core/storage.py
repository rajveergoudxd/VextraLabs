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
            # Try multiple credential sources in order:
            
            # 1. Check for credentials in Docker container location (/code/)
            docker_creds = '/code/firebase_credentials.json'
            if os.path.exists(docker_creds):
                credentials = service_account.Credentials.from_service_account_file(docker_creds)
                cls._client = storage.Client(credentials=credentials)
                logging.info("Using /code/firebase_credentials.json")
                return cls._client
            
            # 2. Check for credentials JSON file in the backend directory (local dev)
            local_creds = os.path.join(os.path.dirname(__file__), '../../firebase_credentials.json')
            if os.path.exists(local_creds):
                credentials = service_account.Credentials.from_service_account_file(local_creds)
                cls._client = storage.Client(credentials=credentials)
                logging.info("Using local firebase_credentials.json")
                return cls._client
            
            # 3. Check GOOGLE_APPLICATION_CREDENTIALS env var
            if settings.GOOGLE_APPLICATION_CREDENTIALS and os.path.exists(settings.GOOGLE_APPLICATION_CREDENTIALS):
                credentials = service_account.Credentials.from_service_account_file(
                    settings.GOOGLE_APPLICATION_CREDENTIALS
                )
                cls._client = storage.Client(credentials=credentials)
                logging.info("Using GOOGLE_APPLICATION_CREDENTIALS")
                return cls._client
            
            # 3. Try default credentials (works on Cloud Run with proper IAM)
            cls._client = storage.Client()
            logging.info("Using default Cloud Run credentials")
            return cls._client
            
        except Exception as e:
            logging.error(f"Failed to initialize storage client: {e}")
            raise

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

