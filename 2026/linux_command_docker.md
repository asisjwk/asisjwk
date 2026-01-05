# docker.raw.sock 에러가 난다면 엔진이 꺼져 있는 것입니다.
docker info

# 가끔 소켓 파일의 권한 문제일 수 있습니다. Docker Desktop이 켜져 있는데도 안 된다면 아래 명령어로 환경 변수를 체크
ls -al /var/run/docker.sock

# --privileged: 커널 이벤트 접근 권한 부여
# --pid=host: 호스트의 프로세스 목록을 볼 수 있게 함 (권장)
docker run --privileged -it --pid=host ubuntu:22.04 /bin/bash

# 1. 필수 도구 설치
apt-get update
apt-get install -y linux-tools-common linux-tools-generic tmux

# 2. 버전에 상관없이 실행 가능한 perf 바이너리 찾아서 연결
# 보통 /usr/lib/linux-tools/ 아래에 버전별로 폴더가 있습니다.
# 설치된 것 중 아무거나 사용해도 기본적인 record/report는 작동합니다.
ls -R /usr/lib/linux-tools/  # 설치된 경로 확인

# 예시: 발견된 경로를 /usr/bin/perf로 심볼릭 링크 (버전 숫자는 다를 수 있음)
ln -sf /usr/lib/linux-tools/$(ls /usr/lib/linux-tools/ | head -n 1)/perf /usr/bin/perf

# 3. 작동 확인
perf --version


# -H: Threads 모드, -b: Batch 모드, -n1: 1회 실행
top -H -b -n 1
# top -H -b -n 1 -p $PID | grep $PID -A $COUNT | grep -v 'top -' | grep -v 'Tasks:' | awk '{print $1}')
#
# 인터랙티브 모드 (기본값): 터미널 화면을 계속 갱신(Refresh)하며 보여줍니다. 화면 제어 코드(ANSI Escape Sequence)를 사용하여 커서 위치를 옮기고 화면을 덮어쓰기 때문에, 이 결과를 파일로 저장하면 특수 문자가 섞여 깨져 보입니다.
#
# 배치 모드 (-b): 화면을 갱신하는 대신, 매 업데이트마다 결과를 **텍스트 스트림(Stream)**으로 계속 쏟아냅니다. 화면 제어 코드를 쓰지 않기 때문에 다른 명령어에 데이터를 넘겨주기에 최적화된 상태가 됩니다.

# 1초 주기로 10번 결과를 기록
top -b -d 1 -n 10 > top_history.txt

# CPU 사용량이 높은 상위 5줄만 잘라내고 싶을 때 (12 lines)
top -b -n 1 | head -n 12

# # 현재 가장 바쁜 PID 하나만 가져오기
echo $(top -b -n 1 | grep -A 1 "PID" | tail -n 1 | awk '{print $1}')


# stress-ng를 사용해 CPU에 30초간 부하를 줍니다. (이 작업은 백그라운드에서 실행하거나 다른 터미널에서 접속하세요)
stress-ng --cpu 2 --timeout 30s &


# 시스템 전체의 CPU 샘플을 10초간 수집합니다.
# -F 99: 초당 99번 샘플링 (오버헤드 방지)
# -a: 모든 CPU 대상, -g: 콜 스택(Call-graph) 포함
perf record -F 99 -a -g -- sleep 10

perf report



# +   98.15%     0.00%  swapper          [kernel.kallsyms]         [k] cpu_startup_entry                                                                       ◆
# +   98.15%     0.02%  swapper          [kernel.kallsyms]         [k] do_idle                                                                                 ▒
# +   98.01%    97.67%  swapper          [kernel.kallsyms]         [k] default_idle_call                                                                       ▒
# +   78.54%     0.00%  swapper          [kernel.kallsyms]         [k] __secondary_switched                                                                    ▒
# +   78.54%     0.00%  swapper          [kernel.kallsyms]         [k] secondary_start_kernel                                                                  ▒
# +   19.61%     0.00%  swapper          [kernel.kallsyms]         [k] __primary_switched                                                                      ▒
# +   19.61%     0.00%  swapper          [kernel.kallsyms]         [k] start_kernel                                                                            ▒
# +   19.61%     0.00%  swapper          [kernel.kallsyms]         [k] arch_call_rest_init                                                                     ▒
# +   19.61%     0.00%  swapper          [kernel.kallsyms]         [k] __noinstr_text_end                                                                      ▒
# +    0.55%     0.00%  kubelet          [kernel.kallsyms]         [k] el0t_64_sync                                                                            ▒
# +    0.55%     0.00%  kubelet          [kernel.kallsyms]         [k] el0t_64_sync_handler                                                                    ▒


# 현재 결과는 **"시스템이 아무 일도 하지 않고 아주 평화로운 상태"**임을 완벽하게 보여주고 있습니다. 그 이유를 핵심만 짚어드릴게요.
#
# 1. swapper와 do_idle의 정체
# 현재 리포트의 98%를 차지하는 **swapper**는 프로세스 이름이지만, 실제로는 CPU Idle(유휴) 상태를 관리하는 커널 스레드입니다.
#
# do_idle / default_idle_call: CPU가 할 일이 없어서 "쉬고 있다"는 뜻입니다.
#
# 즉, 현재 시스템은 CPU 자원의 98%가 비어있는 아주 한가한 상태입니다.
#
# 2. 왜 내 작업이 안 보일까?
# perf record -a로 시스템 전체를 찍었기 때문에, 아무 일도 안 하는 CPU의 유휴 샘플이 대다수를 차지하게 된 것입니다. 실제 의미 있는 분석을 하려면 **CPU를 실제로 사용하는 "부하"**가 있는 상태에서 다시 찍어야 합니다.


# Ctrl + b + %
# Ctrl + ->

# top -H -d 1

# sample during 10 seconds
# perf record -F 99 -a -g -- sleep 10
# perf report


# stressor                                                                       │+   60.00%     0.00%  stress-ng        stress-ng                 [.] 0x0000aaa
# stress-ng: info:  [19854] dispatching hogs: 2 cpu, 1 matrix                    │+   60.00%     0.00%  stress-ng         (deleted)                [.] 0x0000fff
#                                                                                │+   60.00%     0.00%  stress-ng         (deleted)                [.] 0x0000fff
#                                                                                │+   60.00%     0.00%  stress-ng        stress-ng                 [.] 0x0000aaa
#                                                                                │+   60.00%     0.00%  stress-ng        stress-ng                 [.] 0x0000aaa
#                                                                                │+   40.00%     0.00%  stress-ng        stress-ng                 [.] 0x0000aaa
#                                                                                │+   39.05%     0.00%  stress-ng        stress-ng                 [.] 0x0000aaa
#                                                                                │+   38.83%     0.00%  swapper          [kernel.kallsyms]         [k] __seconda
#                                                                                │+   38.83%     0.00%  swapper          [kernel.kallsyms]         [k] secondary
#                                                                                │+   38.83%     0.00%  swapper          [kernel.kallsyms]         [k] cpu_start
#                                                                                │+   38.83%     0.00%  swapper          [kernel.kallsyms]         [k] do_idle
#                                                                                │+   38.83%    37.03%  swapper          [kernel.kallsyms]         [k] default_i
#                                                                                │+   20.00%     0.00%  stress-ng        stress-ng                 [.] 0x0000aaa
#

# CPU 활동 포착: stress-ng가 상단에 올라왔습니다. swapper가 약 38%로 내려갔으니, 시스템 자원의 약 60% 정도가 실제 연산에 활용되고 있음을 알 수 있습니다.
#
# [.] 의 의미: [.]는 사용자 영역(User-level)에서 연산이 일어나고 있음을 뜻합니다. 커널([k]) 부하가 아닌 우리가 의도한 애플리케이션 부하입니다.
#
# 심볼 누락: 0x0000aaa...는 perf가 stress-ng 바이너리 내부의 심볼 테이블을 읽지 못했음을 의미합니다.

# 바이너리에 디버그 정보나 심볼이 포함되어 있지 않으면 주소값만 나옵니다. 컨테이너 내부에서 아래 명령어로 심볼 정보가 포함된 패키지를 설치하거나, 빌드 정보를 확인해야 합니다.

# # 1. 보통 바이너리 설치 시 심볼이 분리되어 있을 수 있습니다. (stress-ng의 경우)
# # apt-get install -y stress-ng-dbgsym || echo "심볼 패키지가 없습니다."
#
# # 2. 만약 직접 빌드한 프로그램이라면 -g 옵션을 넣고 컴파일해야 합니다.
#
# # 1. FlameGraph 툴킷 다운로드
# apt-get install -y git
# git clone https://github.com/brendangregg/FlameGraph
# cd FlameGraph
#
# # 2. perf 데이터를 텍스트로 변환 (stack collapse)
# perf script > out.perf
#
# # 3. 스택 정보 합치기
# ./stackcollapse-perf.pl out.perf > out.folded
#
# # 4. SVG 파일로 렌더링
# ./flamegraph.pl out.folded > stress_perf.svg


# # 1. 실행 중인 컨테이너 ID를 자동으로 찾아 파일을 현재 디렉토리로 복사
# docker cp $(docker ps -q | head -n 1):/FlameGraph/stress_perf.svg ./stress_perf.svg
#
# # 2. 파일이 잘 가져와졌는지 확인
# ls -lh stress_perf.svg
#
# # 3. 브라우저로 즉시 열기 (macOS 전용 명령어)
# open -a "Google Chrome" stress_perf.svg || open stress_perf.svg
