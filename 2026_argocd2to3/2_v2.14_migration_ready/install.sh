#!/bin/bash
set -e

CLUSTER_NAME="argocd-v214-migready"
ARGOCD_VERSION="v2.14.11"

echo "============================================"
echo " ArgoCD v2.14 Migration-Ready Setup"
echo " (v3.3 전환 준비가 완료된 v2.14)"
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

# 마이그레이션 준비 설정 적용
echo "[4/6] Migration-Ready 설정 적용"
kubectl apply -f argocd-cm.yaml
kubectl apply -f argocd-rbac-cm.yaml
kubectl apply -f repo-secret.yaml

echo "[5/6] AppProject & Application 배포"
kubectl apply -f appproject.yaml
kubectl create namespace demo 2>/dev/null || true
kubectl apply -f application.yaml

# argocd-server 재시작 (설정 반영)
echo "[6/6] ArgoCD Server 재시작 (설정 반영)"
kubectl rollout restart deployment/argocd-server -n argocd
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s

# 초기 비밀번호 출력
echo ""
echo "============================================"
echo " 설치 완료! (Migration-Ready v2.14)"
echo "============================================"
INITIAL_PW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Admin Password: ${INITIAL_PW}"
echo ""
echo "UI 접근:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8081:443 --context kind-${CLUSTER_NAME}"
echo "  https://localhost:8081"
echo ""
echo "적용된 변경사항 (v3.3 대비):"
echo "  [1] resourceTrackingMethod: label → annotation"
echo "  [2] repositories: ConfigMap → Secret (repo-secret.yaml)"
echo "  [3] resource.exclusions: 기본 제외 리소스 추가"
echo "  [4] disableApplicationFineGrainedRBACInheritance: false (임시 호환)"
echo "  [5] RBAC: 서브리소스 명시적 권한 추가 (update/*, delete/*/Pod)"
echo "  [6] RBAC: logs 접근 권한 명시적 추가"
echo "  [7] ApplyOutOfSyncOnly 제거"
echo "  [8] CRD ignoreDifferences 추가"
