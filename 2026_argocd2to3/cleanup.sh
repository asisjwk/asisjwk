#!/bin/bash
echo "Kind 클러스터 삭제 중..."
kind delete cluster --name argocd-v214 2>/dev/null && echo "  argocd-v214 삭제 완료" || echo "  argocd-v214 없음"
kind delete cluster --name argocd-v214-migready 2>/dev/null && echo "  argocd-v214-migready 삭제 완료" || echo "  argocd-v214-migready 없음"
kind delete cluster --name argocd-v33 2>/dev/null && echo "  argocd-v33 삭제 완료" || echo "  argocd-v33 없음"
echo "정리 완료!"
