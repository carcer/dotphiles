#!/usr/bin/env python3

"""Read and cache Codex account rate limits for the shared status line."""

from __future__ import annotations

import argparse
import fcntl
import json
import os
from pathlib import Path
import selectors
import shutil
import subprocess
import sys
import tempfile
import time
from typing import Any


DEFAULT_TTL_SECONDS = 300
DEFAULT_MAX_AGE_SECONDS = 900
DEFAULT_RETRY_SECONDS = 60
REQUEST_TIMEOUT_SECONDS = 10


def cache_path() -> Path:
    override = os.environ.get("CODEX_RATE_LIMIT_CACHE")
    if override:
        return Path(override).expanduser()
    cache_home = Path(
        os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))
    )
    return cache_home / "dotphiles" / "codex-rate-limits.json"


def cache_ttl() -> int:
    raw = os.environ.get("CODEX_RATE_LIMIT_CACHE_TTL", str(DEFAULT_TTL_SECONDS))
    try:
        return max(0, int(raw))
    except ValueError:
        return DEFAULT_TTL_SECONDS


def integer_setting(name: str, default: int) -> int:
    try:
        return max(0, int(os.environ.get(name, str(default))))
    except ValueError:
        return default


def load_cache(path: Path) -> dict[str, Any] | None:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    return value if isinstance(value, dict) else None


def is_fresh(value: dict[str, Any] | None) -> bool:
    if not value:
        return False
    fetched_at = value.get("fetchedAt")
    return isinstance(fetched_at, int) and time.time() - fetched_at < cache_ttl()


def is_usable(value: dict[str, Any] | None) -> bool:
    if not value:
        return False
    fetched_at = value.get("fetchedAt")
    max_age = integer_setting(
        "CODEX_RATE_LIMIT_CACHE_MAX_AGE", DEFAULT_MAX_AGE_SECONDS
    )
    return isinstance(fetched_at, int) and time.time() - fetched_at < max_age


def start_background_refresh(path: Path) -> None:
    if os.environ.get("CODEX_RATE_LIMIT_DISABLE_REFRESH") == "1":
        return
    retry_seconds = integer_setting(
        "CODEX_RATE_LIMIT_RETRY_SECONDS", DEFAULT_RETRY_SECONDS
    )
    lock_path = path.with_name(f"{path.name}.lock")
    try:
        if time.time() - lock_path.stat().st_mtime < retry_seconds:
            return
    except OSError:
        pass
    subprocess.Popen(
        [sys.executable, str(Path(__file__).resolve()), "--refresh"],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
        close_fds=True,
    )


def read_response(
    process: subprocess.Popen[str], request_id: int
) -> dict[str, Any]:
    if process.stdout is None:
        raise RuntimeError("Codex app-server stdout is unavailable")

    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    deadline = time.monotonic() + REQUEST_TIMEOUT_SECONDS
    try:
        while time.monotonic() < deadline:
            ready = selector.select(deadline - time.monotonic())
            if not ready:
                break
            line = process.stdout.readline()
            if not line:
                break
            try:
                message = json.loads(line)
            except json.JSONDecodeError:
                continue
            if message.get("id") != request_id:
                continue
            if "error" in message:
                raise RuntimeError(f"Codex app-server error: {message['error']}")
            result = message.get("result")
            if not isinstance(result, dict):
                raise RuntimeError("Codex app-server returned an invalid result")
            return result
    finally:
        selector.close()
    raise TimeoutError(f"Timed out waiting for Codex app-server request {request_id}")


def send_request(
    process: subprocess.Popen[str], request_id: int, method: str, params: Any
) -> dict[str, Any]:
    if process.stdin is None:
        raise RuntimeError("Codex app-server stdin is unavailable")
    message = {"id": request_id, "method": method, "params": params}
    process.stdin.write(json.dumps(message, separators=(",", ":")) + "\n")
    process.stdin.flush()
    return read_response(process, request_id)


def query_rate_limits() -> dict[str, Any]:
    codex = os.environ.get("CODEX_BIN") or shutil.which("codex")
    if not codex:
        raise FileNotFoundError("codex executable not found")

    process = subprocess.Popen(
        [codex, "app-server", "--stdio"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )
    try:
        send_request(
            process,
            1,
            "initialize",
            {
                "clientInfo": {
                    "name": "dotphiles-statusline",
                    "version": "1",
                }
            },
        )
        result = send_request(process, 2, "account/rateLimits/read", None)
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=2)

    by_limit_id = result.get("rateLimitsByLimitId")
    snapshot = by_limit_id.get("codex") if isinstance(by_limit_id, dict) else None
    if not isinstance(snapshot, dict):
        snapshot = result.get("rateLimits")
    if not isinstance(snapshot, dict):
        raise RuntimeError("Codex app-server returned no Codex rate-limit snapshot")

    # Persist only the two quota windows used by the renderer. The full response
    # can contain plan, credit, and reset-credit metadata that does not belong in
    # a frequently-read status-line cache.
    return {
        "fetchedAt": int(time.time()),
        "rateLimits": {
            "primary": snapshot.get("primary"),
            "secondary": snapshot.get("secondary"),
        },
    }


def write_cache(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary_path = Path(temporary)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(value, handle, separators=(",", ":"), sort_keys=True)
            handle.write("\n")
        os.replace(temporary_path, path)
    finally:
        try:
            temporary_path.unlink()
        except FileNotFoundError:
            pass


def refresh(path: Path) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    lock_path = path.with_name(f"{path.name}.lock")
    with lock_path.open("a+", encoding="utf-8") as lock:
        os.chmod(lock_path, 0o600)
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return 0
        if is_fresh(load_cache(path)):
            return 0
        os.utime(lock_path, None)
        try:
            value = query_rate_limits()
            write_cache(path, value)
        except Exception as error:  # Keep status rendering healthy on any failure.
            if os.environ.get("CODEX_RATE_LIMIT_DEBUG") == "1":
                print(f"codex rate-limit refresh failed: {error}", file=sys.stderr)
            return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--refresh", action="store_true")
    args = parser.parse_args()

    path = cache_path()
    if args.refresh:
        return refresh(path)

    value = load_cache(path)
    if not is_fresh(value):
        start_background_refresh(path)
    if is_usable(value):
        json.dump(value, sys.stdout, separators=(",", ":"))
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
