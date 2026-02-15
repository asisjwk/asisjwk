from __future__ import annotations

import json
import uuid
from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.responses import FileResponse, HTMLResponse, JSONResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from .streaming import iter_file_range, parse_range_header

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "uploads"
META_FILE = DATA_DIR / "videos.json"
ALLOWED_EXTENSIONS = {".mp4", ".webm", ".mov"}

app = FastAPI(title="LocalTube")
app.mount("/static", StaticFiles(directory=BASE_DIR / "static"), name="static")
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))


def _ensure_storage() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not META_FILE.exists():
        META_FILE.write_text("[]", encoding="utf-8")


def _load_videos() -> list[dict]:
    _ensure_storage()
    return json.loads(META_FILE.read_text(encoding="utf-8"))


def _save_videos(items: list[dict]) -> None:
    META_FILE.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")


@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    videos = sorted(_load_videos(), key=lambda item: item["created_at"], reverse=True)
    return templates.TemplateResponse("index.html", {"request": request, "videos": videos})


@app.get("/watch/{video_id}", response_class=HTMLResponse)
async def watch(request: Request, video_id: str):
    videos = _load_videos()
    target = next((item for item in videos if item["id"] == video_id), None)
    if not target:
        raise HTTPException(status_code=404, detail="Video not found")

    return templates.TemplateResponse(
        "watch.html",
        {
            "request": request,
            "video": target,
            "recommendations": [item for item in videos if item["id"] != video_id][:8],
        },
    )


@app.post("/upload")
async def upload_video(title: str = Form(...), description: str = Form(""), video_file: UploadFile = File(...)):
    _ensure_storage()

    suffix = Path(video_file.filename or "").suffix.lower()
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Only mp4/webm/mov files are allowed")

    video_id = uuid.uuid4().hex[:12]
    filename = f"{video_id}{suffix}"
    save_path = DATA_DIR / filename

    with save_path.open("wb") as file:
        while chunk := await video_file.read(1024 * 1024):
            file.write(chunk)

    videos = _load_videos()
    videos.append(
        {
            "id": video_id,
            "title": title.strip() or "Untitled",
            "description": description.strip(),
            "filename": filename,
            "created_at": uuid.uuid1().time,
        }
    )
    _save_videos(videos)

    return JSONResponse({"message": "uploaded", "id": video_id})


@app.get("/api/videos")
async def videos_api():
    videos = sorted(_load_videos(), key=lambda item: item["created_at"], reverse=True)
    return {"items": videos}


@app.get("/stream/{video_id}")
async def stream_video(request: Request, video_id: str):
    videos = _load_videos()
    target = next((item for item in videos if item["id"] == video_id), None)
    if not target:
        raise HTTPException(status_code=404, detail="Video not found")

    path = DATA_DIR / target["filename"]
    if not path.exists():
        raise HTTPException(status_code=404, detail="Video file missing")

    file_size = path.stat().st_size
    range_header = request.headers.get("range")

    if not range_header:
        return FileResponse(path, media_type="video/mp4")

    try:
        byte_range = parse_range_header(range_header, file_size)
    except ValueError as error:
        raise HTTPException(status_code=416, detail=str(error)) from error

    headers = {
        "Accept-Ranges": "bytes",
        "Content-Range": f"bytes {byte_range.start}-{byte_range.end}/{file_size}",
        "Content-Length": str(byte_range.length),
        "Content-Type": "video/mp4",
    }
    return StreamingResponse(iter_file_range(path, byte_range), status_code=206, headers=headers)
