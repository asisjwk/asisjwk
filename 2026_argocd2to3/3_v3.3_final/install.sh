#!/bin/bash
set -e

CLUSTER_NAME="argocd-v33"
ARGOCD_VERSION="v3.0.4"  # v3.0 stable (v3.3은 아직 미출시이므로 v3.0 최신 사용)

echo "============================================"
echo " ArgoCD v3.x Final Setup"
echo "============================================"

# Kind 클러스터 생성
echo "[1/6] Kind 클러스터 생성: ${CLUSTER_NAME}"
kind create cluster --name "${CLUSTER_NAME}" --wait 60s 2>/dev/null || echo "클러스터가 이미 존재합니다."
kubectl config use-context "kind-${CLUSTER_NAME}"

# ArgoCD 설치
echo "[2/6] ArgoCD 설치 (${ARGOCD_VERSION})"
kubectl create namespace argocd 2>/dev/null || true
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

# ArgoCD 준비 대기
echo "[3/6] ArgoCD 준비 대기..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s

# v3 설정 적용
echo "[4/6] v3.x 설정 적용"
kubectl apply -f argocd-cm.yaml
kubectl apply -f argocd-rbac-cm.yaml
kubectl apply -f repo-secret.yaml

echo "[5/6] AppProject & Application 배포"
kubectl apply -f appproject.yaml
kubectl create namespace demo 2>/dev/null || true
kubectl apply -f application.yaml

# argocd-server 재시작
echo "[6/6] ArgoCD Server 재시작 (설정 반영)"
kubectl rollout restart deployment/argocd-server -n argocd
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s

# 초기 비밀번호 출력
echo ""
echo "============================================"
echo " 설치 완료! (ArgoCD v3.x)"
echo "============================================"
INITIAL_PW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Admin Password: ${INITIAL_PW}"
echo ""
echo "UI 접근:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8082:443 --context kind-${CLUSTER_NAME}"
echo "  https://localhost:8082"
echo ""
echo "v3.x 특징:"
echo "  - Resource Tracking: annotation (기본값)"
echo "  - Repository: Secret 방식만 지원"
echo "  - RBAC: 서브리소스 권한 자동 상속 없음"
echo "  - Logs: 명시적 권한 필수"
echo "  - Resource Exclusions: 기본 제외 적용"
echo "  - Deprecated 메트릭 제거됨 (argocd_app_info 사용)"
