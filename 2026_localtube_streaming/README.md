# LocalTube Streaming (localhost YouTube-like MVP)

로컬호스트에서 실행 가능한 **간단한 YouTube 스타일 스트리밍 서비스**입니다.

## 기능
- 영상 업로드 (`.mp4`, `.webm`, `.mov`)
- 영상 목록/상세 페이지
- HTTP Range 기반 스트리밍 (`/stream/{video_id}`)
- 업로드 메타데이터 JSON 저장

## 실행
```bash
cd 2026_localtube_streaming
poetry install
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8765
```

브라우저: `http://localhost:8765`

## 테스트
```bash
cd 2026_localtube_streaming
python -m pytest
```

## 문서
- 설계 문서: `docs/design.md`
- 작업 과정 로그: `docs/process_journal/`
