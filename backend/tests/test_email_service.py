import pytest

from app.services import email as email_service

pytestmark = pytest.mark.asyncio


async def test_send_email_passes_smtp_timeout_and_returns_true(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls: list[dict] = []

    async def fake_send(message, **kwargs) -> None:
        calls.append({"message": message, **kwargs})

    monkeypatch.setattr(email_service.aiosmtplib, "send", fake_send)

    sent = await email_service.send_email("a@example.com", "Subject", "<p>Hi</p>")

    assert sent is True
    assert calls[0]["timeout"] == email_service.SMTP_TIMEOUT_SECONDS
    assert calls[0]["message"]["To"] == "a@example.com"


async def test_send_email_returns_false_when_smtp_fails(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    async def failing_send(message, **kwargs) -> None:
        raise ConnectionError("smtp down")

    monkeypatch.setattr(email_service.aiosmtplib, "send", failing_send)

    assert await email_service.send_email("a@example.com", "S", "<p>Hi</p>") is False


async def test_send_email_does_not_swallow_programming_errors(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """A NameError/TypeError is a bug, not a delivery failure: it must raise
    instead of being logged and reported as an ordinary failed send."""

    async def buggy_send(message, **kwargs) -> None:
        raise NameError("boom")

    monkeypatch.setattr(email_service.aiosmtplib, "send", buggy_send)

    with pytest.raises(NameError):
        await email_service.send_email("a@example.com", "S", "<p>Hi</p>")
