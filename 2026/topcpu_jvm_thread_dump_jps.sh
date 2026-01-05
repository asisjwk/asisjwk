#!/bin/bash

# 1. 실행 중인 자바 프로세스 목록 출력 및 선택
echo "Searching for Java processes..."
JAVA_PROCESSES=$(jps -l | grep -v "Jps")

if [ -z "$JAVA_PROCESSES" ]; then
    echo "Error: No Java processes found."
    exit 1
fi

echo "ID   | Process Name"
echo "---------------------------"
echo "$JAVA_PROCESSES"
echo "---------------------------"

# 2. PID 결정 (프로세스가 하나면 자동 선택, 여러 개면 입력 받음)
PROCESS_COUNT=$(echo "$JAVA_PROCESSES" | wc -l)

if [ "$PROCESS_COUNT" -eq 1 ]; then
    PID=$(echo "$JAVA_PROCESSES" | awk '{print $1}')
    echo "Only one Java process found. Analyzing PID: $PID"
else
    read -p "Enter the PID you want to analyze: " PID
fi

# 3. 분석 시작 (기존 로직)
COUNT=5
echo "--- Analyzing Top $COUNT Threads for PID: $PID ---"

# top에서 CPU 사용량이 높은 스레드 추출
TOP_THREADS=$(top -H -b -n 1 -p $PID | grep -A $COUNT "PID USER" | tail -n $COUNT | awk '{print $1}')

for TID in $TOP_THREADS; do
    HEX_TID=$(printf '0x%x' $TID)
    echo "-----------------------------------------------------------------------"
    echo "Thread ID (Dec): $TID | Thread ID (Hex): $HEX_TID"

    # jstack 결과에서 해당 스레드 정보 추출
    jstack $PID | grep -A 20 "$HEX_TID"
done

