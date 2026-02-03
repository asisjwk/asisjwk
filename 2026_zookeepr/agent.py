import yaml, time, os, socket
from kazoo.client import KazooClient

# 설정 및 연결
zk = KazooClient(hosts='zookeeper:2181')
zk.start()

# SERVER_NAME = os.getenv('HOSTNAME', socket.gethostname()) # Container ID
SERVER_NAME = os.getenv('SERVER_NAME', socket.gethostname())
discovery_path = f"/nodes/{SERVER_NAME}"
CMD_PATH = "/config/command"
STATUS_BASE = "/status"

def update_status(STATUS_MSG):
    """서버의 실행 상태를 Zookeeper에 기록 (성공/실패)"""
    status_path = f"{STATUS_BASE}/{SERVER_NAME}"
    zk.ensure_path(STATUS_BASE) # /status 폴더가 없으면 생성

    # 해당 경로에 상태 기록 (이미 있으면 데이터만 업데이트)
    if zk.exists(status_path):
        zk.set(status_path, STATUS_MSG.encode('utf-8'))
    else:
        zk.create(status_path, STATUS_MSG.encode('utf-8'))
    print(f"[*] Status updated to Zookeeper: {STATUS_MSG}", flush=True)

# 1. Discovery: 임시 노드 생성 (서버가 꺼지면 자동 삭제)
zk.ensure_path("/nodes")
zk.create(discovery_path, b"alive", ephemeral=True)
print(f"[*] {SERVER_NAME} registered at /nodes")

@zk.DataWatch(CMD_PATH)
def run_command(data, stat, event):
    if data and stat.version > 0:
        try:
            cmd = yaml.safe_load(data.decode('utf-8'))
            if cmd.get('only', 'all') in ['all', SERVER_NAME]:
                action = cmd.get('action')
                target = cmd.get('target')

                print(f"[EXEC] systemctl {action} {target}", flush=True)

                # 1. 명령 실행 (시뮬레이션)
                # 실제 환경: result = subprocess.run(["sudo", "systemctl", action, target])
                time.sleep(1) # 실행 중인 것처럼 약간의 대기

                # 2. 완료 보고 (Success 기록)
                update_status(f"success (at {time.strftime('%Y-%m-%d %H:%M:%S')})")

        except Exception as e:
            update_status(f"error: {str(e)}")

print(f"[*] Agent {SERVER_NAME} is ready.", flush=True)
while True: time.sleep(1)

