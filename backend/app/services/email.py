import logging

import aiosmtplib
from email.message import EmailMessage

from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


async def send_email(to: str, subject: str, html_body: str) -> None:
    """Send an HTML email. Logs and swallows errors instead of raising,
    so email delivery issues never block the primary request flow."""
    message = EmailMessage()
    message["From"] = settings.smtp_from
    message["To"] = to
    message["Subject"] = subject
    message.set_content("This email requires an HTML-capable client.")
    message.add_alternative(html_body, subtype="html")

    try:
        await aiosmtplib.send(
            message,
            hostname=settings.smtp_host,
            port=settings.smtp_port,
            username=settings.smtp_user or None,
            password=settings.smtp_password or None,
            start_tls=settings.smtp_port == 587,
        )
    except Exception:
        logger.exception("Failed to send email to %s", to)
