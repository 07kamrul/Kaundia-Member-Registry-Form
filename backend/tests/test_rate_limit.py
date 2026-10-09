"""SlidingWindowRateLimiter: per-key windows driven by an injected clock."""

from app.core.rate_limit import SlidingWindowRateLimiter


class _FakeClock:
    def __init__(self) -> None:
        self.now = 0.0

    def __call__(self) -> float:
        return self.now


def test_allows_up_to_the_limit_then_reports_seconds_until_retry() -> None:
    clock = _FakeClock()
    limiter = SlidingWindowRateLimiter(max_requests=2, window_seconds=10, clock=clock)

    first, second = limiter.check("a"), limiter.check("a")
    clock.now = 4.0
    third = limiter.check("a")

    assert (first, second) == (None, None)
    assert third == 6.0


def test_hits_expire_once_the_window_slides_past_them() -> None:
    clock = _FakeClock()
    limiter = SlidingWindowRateLimiter(max_requests=1, window_seconds=10, clock=clock)

    limiter.check("a")
    clock.now = 10.0

    assert limiter.check("a") is None


def test_keys_are_limited_independently() -> None:
    limiter = SlidingWindowRateLimiter(max_requests=1, window_seconds=10, clock=_FakeClock())

    limiter.check("a")

    assert limiter.check("b") is None
    assert limiter.check("a") is not None


def test_rejected_attempts_do_not_extend_the_window() -> None:
    clock = _FakeClock()
    limiter = SlidingWindowRateLimiter(max_requests=1, window_seconds=10, clock=clock)

    limiter.check("a")
    clock.now = 9.0
    limiter.check("a")  # rejected, must not be recorded
    clock.now = 10.0

    assert limiter.check("a") is None
