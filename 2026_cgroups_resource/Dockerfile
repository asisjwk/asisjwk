FROM python:3.9-slim
RUN pip install celery redis
WORKDIR /app
COPY tasks.py .
