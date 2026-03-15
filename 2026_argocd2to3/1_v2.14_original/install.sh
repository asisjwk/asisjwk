#!/bin/bash
set -e

CLUSTER_NAME="argocd-v214"
ARGOCD_VERSION="v2.14.11"

echo "============================================"
echo " ArgoCD v2.14 Original Setup"
echo "============================================"

# Kind 클러스터 생성
echo "[1/5] Kind 클러스터 생성: ${CLUSTER_NAME}"
kind create cluster --name "${CLUSTER_NAME}" --wait 60s 2>/dev/null || echo "클러스터가 이미 존재합니다."
kubectl config use-context "kind-${CLUSTER_NAME}"

# ArgoCD 네임스페이스 생성
echo "[2/5] ArgoCD 설치 (${ARGOCD_VERSION})"
kubectl create namespace argocd 2>/dev/null || true
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

# ArgoCD가 Ready 될 때까지 대기
echo "[3/5] ArgoCD 준비 대기..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s

# 커스텀 설정 적용
echo "[4/5] v2.14 설정 적용"
kubectl apply -f argocd-cm.yaml
kubectl apply -f argocd-rbac-cm.yaml
kubectl apply -f appproject.yaml

# demo 네임스페이스 생성 및 Application 배포
echo "[5/5] Application 배포"
kubectl create namespace demo 2>/dev/null || true
kubectl apply -f application.yaml

# 초기 비밀번호 출력
echo ""
echo "============================================"
echo " 설치 완료!"
echo "============================================"
INITIAL_PW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Admin Password: ${INITIAL_PW}"
echo ""
echo "UI 접근:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443 --context kind-${CLUSTER_NAME}"
echo "  https://localhost:8080"
echo ""
echo "확인 포인트:"
echo "  - Resource Tracking: label 방식"
echo "  - Repository: ConfigMap에 정의됨"
echo "  - RBAC: update/delete가 서브리소스에 자동 상속"
echo "  - Logs: 별도 권한 없이 접근 가능"
