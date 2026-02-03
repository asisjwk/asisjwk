from celery import Celery
import time

app = Celery('tasks', broker='redis://redis:6379/0')

@app.task
def long_task():
    time.sleep(30)
    return "Done"
