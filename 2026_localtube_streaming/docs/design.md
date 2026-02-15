# LocalTube 설계 문서

## 1. 목표
- 단일 개발 환경(localhost)에서 빠르게 데모 가능한 스트리밍 플랫폼 구현
- 업로드/목록/재생까지 한 흐름 완성
- 대용량 파일의 부분 전송(Range Request) 지원

## 2. 아키텍처
- Backend: FastAPI
- Frontend: Jinja2 template + vanilla JS + CSS
- Storage:
  - 비디오 파일: `app/uploads/`
  - 메타데이터: `app/uploads/videos.json`

## 3. API 요약
- `GET /`: 메인 페이지 + 업로드 폼 + 최신 영상
- `POST /upload`: 영상 업로드 및 메타 저장
- `GET /watch/{video_id}`: 플레이어 페이지
- `GET /stream/{video_id}`: 파일 스트리밍 (Range 지원)
- `GET /api/videos`: JSON 목록

## 4. 스트리밍 전략
- Range 헤더 없으면 일반 파일 응답
- Range 헤더 있으면 `206 Partial Content` + `Content-Range` 반환
- 서버에서 지정 바이트 구간만 읽어서 전송

## 5. 확장 계획
- 썸네일 생성(ffmpeg)
- 채널/구독/댓글 모델
- HLS 변환 및 adaptive bitrate
- DB(PostgreSQL)로 메타데이터 이전
