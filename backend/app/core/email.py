from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from app.core.config import settings
from pydantic import EmailStr
import logging

class EmailService:
    @staticmethod
    def _get_config() -> ConnectionConfig:
        return ConnectionConfig(
            MAIL_USERNAME=settings.MAIL_USERNAME,
            MAIL_PASSWORD=settings.MAIL_PASSWORD,
            MAIL_FROM=settings.MAIL_FROM,
            MAIL_PORT=settings.MAIL_PORT,
            MAIL_SERVER=settings.MAIL_SERVER,
            MAIL_STARTTLS=settings.MAIL_STARTTLS,
            MAIL_SSL_TLS=settings.MAIL_SSL_TLS,
            USE_CREDENTIALS=settings.USE_CREDENTIALS,
            VALIDATE_CERTS=settings.VALIDATE_CERTS
        )

    @staticmethod
    async def send_otp_email(email: EmailStr, otp: str, purpose: str = "verification"):
        """
        Sends an OTP email to the user.
        """
        if not settings.MAIL_SERVER or not settings.MAIL_USERNAME:
            logging.warning("SMTP settings not configured. Skipping email sending.")
            return

        conf = EmailService._get_config()
        
        html = f"""
        <html>
            <body style="font-family: Arial, sans-serif; padding: 20px;">
                <h2 style="color: #333;">Verification Code</h2>
                <p>Hello,</p>
                <p>Your verification code for <strong>{purpose}</strong> is:</p>
                <h1 style="color: #4CAF50; font-size: 32px; letter-spacing: 5px;">{otp}</h1>
                <p>This code will expire in 15 minutes.</p>
                <p>If you did not request this, please ignore this email.</p>
                <br>
                <p>Best regards,<br>Vextra Team</p>
            </body>
        </html>
        """

        message = MessageSchema(
            subject=f"Your Vextra Verification Code: {otp}",
            recipients=[email],
            body=html,
            subtype=MessageType.html
        )

        fm = FastMail(conf)
        try:
            await fm.send_message(message)
            logging.info(f"OTP email sent to {email}")
        except Exception as e:
            logging.error(f"Failed to send email to {email}: {e}")
            raise e
