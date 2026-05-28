import os
import smtplib
import time
from email.message import EmailMessage

class EmailService:
    """Notification email service"""

    def __init__(self) -> None:
        email_from = os.getenv("EMAIL_FROM")
        email_to = os.getenv("EMAIL_TO")
        app_password = os.getenv("APP_PASSWORD")

        if not email_from or not email_to or not app_password:
            raise ValueError("On or more keys are missing from .env. Required keys are \"EMAIL_FROM\", \"EMAIL_TO\", and \"APP_PASSWORD\"")
        
        self._email_from = email_from
        self._email_to = email_to
        self._app_password = app_password

    def _send_message(self, subject: str, content: str) -> None:
        """Sends an email"""
        msg = EmailMessage()
        msg["Subject"] = subject
        msg["From"] = self._email_from
        msg["To"] = self._email_to
        msg.set_content(content)

        # Try sending the email
        try:
            with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
                smtp.login(self._email_from, self._app_password)
                smtp.send_message(msg)
            print("Email sent successfully")
        except Exception as e:
            print(f"Error sending email: {e}")

    def send_failure_email(self, package_name: str, step: str | None, error: str | None) -> None:
        """Formats and sends a package failure email"""
        subject = f"Package {package_name} failure"

        body = f"Package: {package_name}\nTime: {time.time()}" + (f"\nStep: {step}" if step else "") + (f"\nError: {error}" if error else "")

        self._send_message(subject, body)