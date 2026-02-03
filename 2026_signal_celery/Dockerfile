FROM python:3.10-slim

# strace 및 필수 패키지 설치
RUN apt-get update && apt-get install -y strace procps && rm -rf /var/lib/apt/lists/*

RUN pip install celery redis

WORKDIR /app
# 테스트용 빈 파일 생성 (실제 작업 없어도 워커는 실행됨)
RUN echo "from celery import Celery\napp = Celery('tasks', broker='redis://redis:6379/0')" > tasks.py

CMD ["sleep", "infinity"]
