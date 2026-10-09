"""In-process sliding-window rate limiting."""

import time
from collections import deque
from collections.abc import Callable, Hashable


class SlidingWindowRateLimiter:
    """Allows at most `max_requests` hits per key within any `window_seconds` span.

    State lives in this process only: with several app instances each one
    enforces its own window, so the effective limit is per instance. That is
    enough to stop a single account scraping a directory endpoint; move the
    counters to a shared store if the API is ever scaled out.
    """

    def __init__(
        self,
        max_requests: int,
        window_seconds: float,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        if max_requests < 1 or window_seconds <= 0:
            raise ValueError("max_requests must be >= 1 and window_seconds must be > 0")
        self._max_requests = max_requests
        self._window_seconds = float(window_seconds)
        self._clock = clock
        self._hits: dict[Hashable, deque[float]] = {}

    def check(self, key: Hashable) -> float | None:
        """Record a hit for `key` and return None; or, when `key` is already at
        its limit, record nothing and return the seconds until a retry succeeds."""
        now = self._clock()
        hits = self._hits.setdefault(key, deque())
        while hits and hits[0] <= now - self._window_seconds:
            hits.popleft()
        if len(hits) >= self._max_requests:
            return hits[0] + self._window_seconds - now
        hits.append(now)
        return None
