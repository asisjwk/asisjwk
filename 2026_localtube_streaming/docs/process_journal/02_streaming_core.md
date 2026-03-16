# 02 - Streaming Core

- `parse_range_header` 구현
  - 일반 범위, open-ended 범위, suffix 범위 처리
  - 잘못된 범위 요청은 예외 처리
- `iter_file_range` 구현
  - 파일 seek 후 필요한 바이트 수만 청크 전송
