# ArgoCD v2.14 → v3.x Migration Hands-On Lab

로컬 Kind 클러스터 3개를 띄워서 ArgoCD v2.14 → v3.x 마이그레이션 과정을 단계별로 비교하는 실습입니다.

## 구조

```
2026_argocd2to3/
├── sample-app/                    # 배포 대상 샘플 앱 (nginx)
├── 1_v2.14_original/              # [AS-IS] ArgoCD v2.14 원본
├── 2_v2.14_migration_ready/       # [TRANSITION] v3 전환 준비가 된 v2.14
├── 3_v3.3_final/                  # [TO-BE] ArgoCD v3.x 최종
├── run-all.sh                     # 전체 실행
└── cleanup.sh                     # 전체 정리
```

## 사전 요구사항

```bash
# Docker Desktop 실행
# kind 설치
brew install kind

# kubectl 설치
brew install kubectl
```

## 실행

```bash
# 전체 한번에 실행 (Kind 클러스터 3개 생성)
bash run-all.sh

# 또는 개별 실행
cd 1_v2.14_original && bash install.sh
cd 2_v2.14_migration_ready && bash install.sh
cd 3_v3.3_final && bash install.sh
```

## UI 접근 (각각 별도 터미널)

| 단계 | 포트 | 컨텍스트 |
|------|------|----------|
| v2.14 Original | https://localhost:8080 | `kind-argocd-v214` |
| v2.14 Migration-Ready | https://localhost:8081 | `kind-argocd-v214-migready` |
| v3.x Final | https://localhost:8082 | `kind-argocd-v33` |

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 --context kind-argocd-v214
kubectl port-forward svc/argocd-server -n argocd 8081:443 --context kind-argocd-v214-migready
kubectl port-forward svc/argocd-server -n argocd 8082:443 --context kind-argocd-v33
```

로그인: `admin` / `admin`

## Breaking Changes 요약 (8개 변경점)

### 1. Resource Tracking 방식 변경
- **v2.14**: `label`로 리소스를 추적 (Deployment에 `app.kubernetes.io/instance` 라벨 부착)
- **v3.x**: `annotation`으로 추적 (라벨 대신 annotation에 추적 정보 기록)
```bash
# v2.14: label에 argocd 추적 정보가 있음
kubectl get deploy guestbook-ui -n demo --context kind-argocd-v214 -o jsonpath='{.metadata.labels}' | jq .

# v3.x: annotation에 추적 정보가 있음
kubectl get deploy guestbook-ui -n demo --context kind-argocd-v33 -o jsonpath='{.metadata.annotations}' | jq .
```

### 2. Repository 설정: ConfigMap → Secret
- **v2.14**: `argocd-cm` ConfigMap의 `repositories:` 필드에 레포 URL을 직접 기입
- **v3.x**: ConfigMap의 `repositories:` 필드 **삭제됨**. `argocd.argoproj.io/secret-type: repository` 라벨이 붙은 Secret만 인식
```bash
# v2.14: ConfigMap에서 repo 확인
kubectl get cm argocd-cm -n argocd --context kind-argocd-v214 -o jsonpath='{.data.repositories}'

# v3.x: Secret에서 repo 확인
kubectl get secret repo-demo -n argocd --context kind-argocd-v33 -o jsonpath='{.data.url}' | base64 -d
```

### 3. Resource Exclusions 기본값 추가
- **v2.14**: 모든 리소스를 감시 (Endpoints, Events 등 노이즈 리소스 포함)
- **v3.x**: `Endpoints`, `Events`, `Leases`, `TokenReviews`가 기본 제외됨 → API 서버 부하 감소
```bash
# v2.14: resource.exclusions 없음
kubectl get cm argocd-cm -n argocd --context kind-argocd-v214 -o jsonpath='{.data.resource\.exclusions}'
# (출력 없음)

# v3.x: 기본 제외 리소스 있음
kubectl get cm argocd-cm -n argocd --context kind-argocd-v33 -o jsonpath='{.data.resource\.exclusions}'
# Endpoints, Events, Leases, TokenReviews 출력
```

### 4. Fine-Grained RBAC 서브리소스 상속 제거
- **v2.14**: `applications, update`를 주면 해당 앱의 Pod/Deployment 등 서브리소스도 update 가능 (자동 상속)
- **v3.x**: 앱 권한과 서브리소스 권한이 **분리됨**. Pod를 삭제하려면 `delete/*/Pod/*/*`를 별도로 명시해야 함
```bash
# 두 버전의 RBAC 정책 비교
diff <(kubectl get cm argocd-rbac-cm -n argocd --context kind-argocd-v214 -o jsonpath='{.data.policy\.csv}') \
     <(kubectl get cm argocd-rbac-cm -n argocd --context kind-argocd-v33 -o jsonpath='{.data.policy\.csv}')
# v3.x에서 update/*, delete/*/Pod/*/* 등의 라인이 추가된 것을 볼 수 있음
```

### 5. Logs 접근 권한 필수화
- **v2.14**: 별도 권한 없이 앱에 접근 가능하면 Pod 로그도 볼 수 있음
- **v3.x**: `logs, get` 권한이 없으면 UI에서 Pod 로그 탭 클릭 시 **403 Forbidden** 반환
```bash
# v3.x의 RBAC에서 logs 권한 확인
kubectl get cm argocd-rbac-cm -n argocd --context kind-argocd-v33 -o jsonpath='{.data.policy\.csv}' | grep logs
# p, role:developer, logs, get, */*, allow  ← 이 라인이 있어야 로그 접근 가능
```

### 6. ApplyOutOfSyncOnly 옵션 위험
- **v2.14**: `ApplyOutOfSyncOnly=true` 사용 시 OutOfSync 리소스만 apply (sync 속도 향상)
- **v3.x**: 이 옵션 사용 시 prune 대상 리소스를 감지하지 못해 **삭제되어야 할 리소스가 클러스터에 남음** (orphaned resource). 제거 권장
```bash
# v2.14: ApplyOutOfSyncOnly 있음
kubectl get app demo-app -n argocd --context kind-argocd-v214 -o jsonpath='{.spec.syncPolicy.syncOptions}'
# ["CreateNamespace=true","ApplyOutOfSyncOnly=true"]

# v3.x: 제거됨
kubectl get app demo-app -n argocd --context kind-argocd-v33 -o jsonpath='{.spec.syncPolicy.syncOptions}'
# ["CreateNamespace=true"]
```

### 7. CRD preserveUnknownFields diff
- **v2.14**: CRD의 `spec.preserveUnknownFields` 필드를 ArgoCD가 무시
- **v3.x**: 이 필드의 처리 방식이 달라져서 ArgoCD가 **매 sync마다 diff를 감지**하고 OutOfSync 상태가 반복됨. `ignoreDifferences`로 해당 경로를 명시해야 함
```bash
# v3.x Application에 ignoreDifferences 설정 확인
kubectl get app demo-app -n argocd --context kind-argocd-v33 -o jsonpath='{.spec.ignoreDifferences}' | jq .
# /spec/preserveUnknownFields 경로가 ignore 되어 있어야 함
```

### 8. 기타 참고사항
- **Deprecated 메트릭**: `argocd_app_sync_status`, `argocd_app_health_status` → `argocd_app_info` 라벨로 통합
- **Dex 인증**: RBAC subject가 `sub` claim → `federated_claims.user_id`로 변경
- **Helm null 값**: `someConfig: null` → v3 + Helm 3.17.1에서 에러. `~`로 대체하거나 해당 키 자체를 삭제

## 비교 확인 포인트

3개 ArgoCD UI를 나란히 열어서 비교:

| 확인 항목 | 어디서 보는지 | v2.14에서 보이는 것 | v3.x에서 보이는 것 |
|-----------|--------------|--------------------|--------------------|
| Repo 설정 방식 | Settings → Repositories | ConfigMap 기반으로 등록된 repo | Secret 기반으로 등록된 repo |
| Sync 상태 | Applications → demo-app | Synced (ApplyOutOfSyncOnly 포함) | Synced (ApplyOutOfSyncOnly 없음) |
| RBAC 차이 | UI에서 Pod 클릭 → Delete 버튼 | developer가 클릭 가능 (자동 상속) | 명시적 권한 없으면 버튼 비활성화 |
| Logs 접근 | UI에서 Pod 클릭 → Logs 탭 | 누구나 볼 수 있음 | `logs, get` 권한 없으면 403 |

## 정리

```bash
bash cleanup.sh
```
