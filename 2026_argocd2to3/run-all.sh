#!/bin/bash
set -e

echo "============================================================"
echo " ArgoCD v2.14 → v3.3 Migration Hands-On Lab"
echo " 3개의 Kind 클러스터를 생성하여 비교합니다"
echo "============================================================"
echo ""
echo "사전 요구사항:"
echo "  - Docker Desktop 실행 중"
echo "  - kind 설치됨 (brew install kind)"
echo "  - kubectl 설치됨"
echo ""
read -p "계속하시겠습니까? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "취소됨."
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "========== [1/3] v2.14 Original =========="
cd "${SCRIPT_DIR}/1_v2.14_original" && bash install.sh

echo ""
echo "========== [2/3] v2.14 Migration-Ready =========="
cd "${SCRIPT_DIR}/2_v2.14_migration_ready" && bash install.sh

echo ""
echo "========== [3/3] v3.x Final =========="
cd "${SCRIPT_DIR}/3_v3.3_final" && bash install.sh

echo ""
echo "============================================================"
echo " 모든 클러스터 설치 완료!"
echo "============================================================"
echo ""
echo "UI 접근 (각각 별도 터미널에서 실행):"
echo ""
echo "  [v2.14 Original]"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443 --context kind-argocd-v214"
echo "  → https://localhost:8080"
echo ""
echo "  [v2.14 Migration-Ready]"
echo "  kubectl port-forward svc/argocd-server -n argocd 8081:443 --context kind-argocd-v214-migready"
echo "  → https://localhost:8081"
echo ""
echo "  [v3.x Final]"
echo "  kubectl port-forward svc/argocd-server -n argocd 8082:443 --context kind-argocd-v33"
echo "  → https://localhost:8082"
echo ""
echo "정리: bash cleanup.sh"
