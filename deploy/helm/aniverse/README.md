# Aniverse Helm 차트

`deploy/k8s`(kustomize)를 대체하는 Helm 차트. web(Deployment) + db(StatefulSet)를
같은 차트로 배포하되, `persistence.enabled` 값으로 DB 볼륨을 emptyDir ↔ PVC 전환한다.

| 값 | 랩/로컬 (기본) | EKS |
|----|----------------|-----|
| `persistence.enabled` | `false` → emptyDir (Pod 삭제 시 데이터 소실) | `true` → `volumeClaimTemplates` (PVC) |
| `persistence.storageClassName` | 사용 안 함 | 실제 StorageClass 이름 필수 (`kubectl get sc`로 확인) |

## 사용

렌더링만 확인 (클러스터 미적용):

```bash
helm template aniverse deploy/helm/aniverse
```

랩/로컬 클러스터에 설치 (기존 kustomize와 동일 동작 — emptyDir):

```bash
helm install aniverse deploy/helm/aniverse -n aniverse --create-namespace
```

EKS 등에 설치 (PVC 사용, 값은 실제 환경에 맞게 교체):

```bash
helm install aniverse deploy/helm/aniverse -n aniverse --create-namespace \
  -f deploy/helm/aniverse/values-eks.yaml \
  --set-string secrets.DJANGO_SECRET_KEY=... \
  --set-string secrets.DB_PASSWORD=... \
  --set-string secrets.DB_ROOT_PASSWORD=...
```

기존 릴리스 업그레이드:

```bash
helm upgrade aniverse deploy/helm/aniverse -n aniverse -f <values 파일>
```

## PVC 동작 확인 (EKS 전환 시 필수 검증)

```bash
kubectl -n aniverse get pvc                     # data-aniverse-db-0 Bound 확인
kubectl -n aniverse delete pod aniverse-db-0     # Pod 재생성 후에도
kubectl -n aniverse exec -it aniverse-db-0 -- mariadb -uroot -p -e "SHOW DATABASES;"  # 데이터 남아있는지 확인
```

### minikube로 먼저 검증 (랩/EKS 둘 다 StorageClass 없는 상태라)

랩 클러스터는 아직 StorageClass가 없고 EKS도 없는 상태라, PVC 동작 자체는
**minikube**로 먼저 확인한다 (`docs/local-k8s.md`). minikube는 기본
StorageClass(`standard`)가 이미 있어서 `values-lab-pvc.yaml`의
`storageClassName: ""` 그대로 바로 PVC가 생성된다. `aniverse` 운영 릴리스와
분리하기 위해 별도 네임스페이스로 설치한다:

```bash
minikube start --driver=docker
eval $(minikube docker-env)
docker build -t aniverse:local .          # base values.yaml 의 image 그대로 사용

helm upgrade --install aniverse-pvc-test deploy/helm/aniverse \
  -n aniverse-pvc-test --create-namespace \
  -f deploy/helm/aniverse/values-lab-pvc.yaml

kubectl -n aniverse-pvc-test get pvc            # Bound, STORAGECLASS=standard 확인
kubectl -n aniverse-pvc-test delete pod aniverse-db-0
kubectl -n aniverse-pvc-test get pvc            # 재생성 후에도 그대로인지

# 검증 끝나면 정리
helm uninstall aniverse-pvc-test -n aniverse-pvc-test
kubectl delete ns aniverse-pvc-test
```

랩 클러스터에 실제 StorageClass가 생기거나 EKS가 준비되면, 같은 파일에
`storageClassName`만 채워서 그쪽에서도 동일하게 재검증한다.

## Argo CD (현우 · 계획된 GitOps)

랩/EKS 배포는 **Helm 차트를 Argo가 sync** 한다.

| 환경 | Application | values |
|------|----------------|--------|
| 랩 | `deploy/argocd/application-lab-helm.yaml` | `values-lab-ecr.yaml` |
| EKS | `deploy/argocd/application-eks-helm.yaml` | `values-eks.yaml` |

문서: [`docs/argocd-lab.md`](../../docs/argocd-lab.md)

## 남은 작업 (TODO)

- [x] `image.repository` ECR URI (`values-lab-ecr.yaml` / `values-eks.yaml`) — 현우
- [x] static → S3 (`docs/static-s3.md`) — 현우
- [ ] `anime-project-infra`에서 EKS 실제 StorageClass 이름 확인 → `values-eks.yaml` (서이)
- [ ] `secrets.*` 운영값은 git에 커밋하지 말고 CI/`--set-string`으로 주입
- [x] (선택) `data/aniverse_backup.sql` post-install Job — `dbRestore.enabled` (values-eks)
- [ ] (선택) Actions가 `image.tag`를 `sha-*`로 자동 갱신
- [ ] EKS Pod IRSA 후 collectstatic Job 검토

## DB 자동 복구 (`dbRestore`)

`values-eks.yaml` 에서 `dbRestore.enabled: true` 이면 Argo sync 시 Job `aniverse-db-restore` 가:

1. GitHub raw(`dbRestore.sqlUrl`)에서 덤프 download  
2. DB ready 대기 후 테이블 수 < `minTables` 이면 import  
3. 이미 데이터가 있으면 skip  

덤프 원본: 레포 `data/aniverse_backup.sql` (ConfigMap 미사용).