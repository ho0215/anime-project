# DB SQL 자동 복구 (destroy → 재apply)

EKS MariaDB는 PVC라 **Terraform destroy 시 데이터가 사라집니다.**  
스키마·시드는 Git의 SQL 덤프로 다시 넣고, 사진 등은 S3 sync로 복구합니다.

## 자동 경로 (EKS)

Helm `dbRestore.enabled: true` (`values-eks.yaml`):

1. Argo가 sync 하면 Job `aniverse-db-restore` 실행 (sync-wave 5)
2. 테이블 수 &lt; 20 이면 `deploy/helm/aniverse/files/aniverse_backup.sql` import
3. 이미 데이터가 있으면 no-op

NetworkPolicy는 `app: aniverse-db-restore` → DB 3306 을 허용합니다.

```bash
kubectl -n aniverse get job aniverse-db-restore
kubectl -n aniverse logs job/aniverse-db-restore
# Skip restore — schema already present.  또는 Restore complete.
```

## 덤프 갱신

```bash
# 예: 로컬/클러스터에서 dump 후
cp data/aniverse_backup.sql deploy/helm/aniverse/files/aniverse_backup.sql
git add data/aniverse_backup.sql deploy/helm/aniverse/files/aniverse_backup.sql
```

## destroy 후 전체 복구 순서

1. Terraform apply (keep-dns destroy 반대)
2. Argo sync / helm → DB Job이 SQL 복구 + 앱 기동
3. Actions **Sync media → S3** (또는 apply 후 restore-s3-assets)
4. `curl -sI https://aniverse.my/health/`

관련: [static-s3.md](./static-s3.md) (media), infra `docs/eks-start-stop.md`
