from app.streaming import parse_range_header


def test_default_range_uses_chunk_size():
    byte_range = parse_range_header(None, 10_000, chunk_size=1000)
    assert byte_range.start == 0
    assert byte_range.end == 999


def test_open_ended_range():
    byte_range = parse_range_header("bytes=100-", 1000, chunk_size=200)
    assert byte_range.start == 100
    assert byte_range.end == 299


def test_suffix_range():
    byte_range = parse_range_header("bytes=-120", 1000)
    assert byte_range.start == 880
    assert byte_range.end == 999


def test_invalid_multi_range_raises_value_error():
    try:
        parse_range_header("bytes=0-100,200-300", 1000)
        assert False, "expected ValueError"
    except ValueError as exc:
        assert "Multiple ranges" in str(exc)
