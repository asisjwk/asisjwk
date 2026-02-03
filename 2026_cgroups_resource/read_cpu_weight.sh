# read_cpu_weight.sh
echo "worker-high"
# 특정 컨테이너(high)의 ID 확인
CONTAINER_ID=$(docker ps -aqf "name=worker-high")
# cgroups v2 경로에서 weight 값 확인 (docker-compose의 cpu_shares와 매핑됨)
docker exec $CONTAINER_ID cat /sys/fs/cgroup/cpu.weight
echo "worker-mid"
CONTAINER_ID=$(docker ps -aqf "name=worker-mid")
docker exec $CONTAINER_ID cat /sys/fs/cgroup/cpu.weight
echo "worker-low"
CONTAINER_ID=$(docker ps -aqf "name=worker-low")
docker exec $CONTAINER_ID cat /sys/fs/cgroup/cpu.weight
