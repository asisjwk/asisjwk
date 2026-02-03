# run_stress_low_only.py
from celery import Celery
import time
app = Celery('tasks', broker='redis://localhost:6379/0')
def run_test():
    print("--- cgroups v2 자원 경합 테스트 시작 ---")
    # 각 워커의 concurrency(기본값은 CPU 코어 수)를 고려하여 넉넉히 던집니다.
    task_count = 20
    print(f"low_priority 큐에만 {task_count}개 작업 투입...")
    for _ in range(task_count):
        app.send_task('tasks.cpu_stress_test', queue='low_priority')
    print("\n작업 완료. 'docker stats'를 확인하세요!")
if __name__ == '__main__':
    run_test()
