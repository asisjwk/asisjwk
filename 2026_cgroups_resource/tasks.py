# tasks.py
from celery import Celery
import os

# Redis를 브로커로 사용
app = Celery('tasks', broker='redis://redis:6379/0')

@app.task
def cpu_stress_test():
    print(f"Process ID {os.getpid()} 가 작업을 시작합니다.")
    # CPU 점유를 위한 무한 루프 (task 당 한 코어에 할당. 5 core에 모두 실행하려면 task 5번 호출)
    x = 0
    while True:
        x += 1
