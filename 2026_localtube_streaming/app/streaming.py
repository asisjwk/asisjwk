from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ByteRange:
    start: int
    end: int

    @property
    def length(self) -> int:
        return self.end - self.start + 1


def parse_range_header(range_header: str | None, file_size: int, chunk_size: int = 1024 * 1024) -> ByteRange:
    """Parse HTTP range header and fallback to first chunk when missing.

    Supports forms:
    - bytes=START-END
    - bytes=START-
    - bytes=-SUFFIX
    """
    if file_size <= 0:
        raise ValueError("file_size must be positive")

    if not range_header:
        end = min(chunk_size - 1, file_size - 1)
        return ByteRange(start=0, end=end)

    if not range_header.startswith("bytes="):
        raise ValueError("Invalid range unit")

    raw = range_header.replace("bytes=", "", 1).strip()
    if "," in raw:
        raise ValueError("Multiple ranges are not supported")

    start_raw, end_raw = raw.split("-", maxsplit=1)

    if start_raw == "":
        suffix = int(end_raw)
        if suffix <= 0:
            raise ValueError("Suffix range must be positive")
        start = max(file_size - suffix, 0)
        end = file_size - 1
        return ByteRange(start=start, end=end)

    start = int(start_raw)
    if start >= file_size or start < 0:
        raise ValueError("Range start out of bounds")

    if end_raw == "":
        end = min(start + chunk_size - 1, file_size - 1)
        return ByteRange(start=start, end=end)

    end = int(end_raw)
    if end < start:
        raise ValueError("Range end must be >= start")
    end = min(end, file_size - 1)
    return ByteRange(start=start, end=end)


def iter_file_range(path: Path, byte_range: ByteRange, buffer_size: int = 64 * 1024):
    with path.open("rb") as file:
        file.seek(byte_range.start)
        remaining = byte_range.length

        while remaining > 0:
            chunk = file.read(min(buffer_size, remaining))
            if not chunk:
                break
            yield chunk
            remaining -= len(chunk)
