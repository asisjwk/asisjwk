import signal
import time
from celery import Celery

app = Celery('tasks', broker='redis://localhost:6379/0')

def long_running_handler(signum, frame):
    print("SIGTERM received but I am ignoring it for 60 seconds...")
    time.sleep(60)

# SIGTERM 시그널을 받아도 60초간 대기하도록 설정
signal.signal(signal.SIGTERM, long_running_handler)

@app.task
def heavy_task():
    while True:
        time.sleep(1)
