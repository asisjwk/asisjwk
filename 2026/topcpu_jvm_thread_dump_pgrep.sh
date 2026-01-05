#!/bin/bash

# 1. 자바 프로세스 자동 탐색 (표준 도구 활용)
PID=$(pgrep -x java | head -n 1)
[ -z "$PID" ] && PID=$(ps -ef | grep java | grep -v grep | awk '{print $2}' | head -n 1)

if [ -z "$PID" ]; then
    echo "Error: Java process not found."
    exit 1
fi

echo "======================================================================"
echo " [Deep Dive] Java CPU & Source Line Analysis"
echo " Target PID : $PID"
echo " Time       : $(date)"
echo "======================================================================"

# 2. jstack 덤프 (임시 저장)
JSTACK_FILE="/tmp/jstack_deep_$PID.txt"
jstack $PID > $JSTACK_FILE

# 3. CPU 사용량 상위 5개 스레드 추출
TOP_THREADS=$(top -H -b -n 1 -p $PID | grep -A 5 "PID USER" | tail -n 5)

echo -e "CPU%\tTID(Hex)\tThread Stack Detail (Source Line)"
echo "----------------------------------------------------------------------"

while read -r line; do
    [ -z "$line" ] && continue
    TID=$(echo $line | awk '{print $1}')
    CPU=$(echo $line | awk '{print $9}')
    HEX_TID=$(printf '0x%x' $TID)

    echo -e "${CPU}%\t${HEX_TID}\t------------------------------------------------"

    # jstack에서 해당 nid를 찾아 헤더와 상위 5줄의 스택(라인 정보 포함) 출력
    # 1. 스레드 이름/상태 출력
    grep "nid=$HEX_TID" $JSTACK_FILE | sed 's/^/         /'

    # 2. 실제 소스 라인 정보가 포함된 스택 트레이스 (Native Method 제외)
    grep -A 10 "$HEX_TID" $JSTACK_FILE | grep "at " | head -n 5 | sed 's/^[[:space:]]*/         /'

done <<< "$TOP_THREADS"

rm $JSTACK_FILE

