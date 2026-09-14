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

## 남은 작업 (TODO)

- [ ] `anime-project-infra`에서 EKS의 실제 StorageClass 이름 확인 → `values-eks.yaml` 교체
- [ ] `image.repository`를 ECR URI로 교체 (`docker-build.yml`의 ECR push 활성화 후)
- [ ] `secrets.*` 운영값을 git에 커밋하지 말고 CI 시크릿에서 `--set-string`으로 주입
- [ ] (선택) 최초 배포 시 `data/aniverse_backup.sql` 자동 복원용 `post-install` Job hook 추가
