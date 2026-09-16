# DB SQL 자동 복구 (destroy → 재apply)

EKS MariaDB는 PVC라 **Terraform destroy 시 데이터가 사라집니다.**  
스키마·시드는 Git의 SQL 덤프로 다시 넣고, 사진 등은 S3 sync로 복구합니다.

## 자동 경로 (EKS)

Helm `dbRestore.enabled: true` (`values-eks.yaml`):

1. Argo sync 시 Job `aniverse-db-restore` (sync-wave 5)
2. initContainer가 `dbRestore.sqlUrl` (GitHub raw) 에서 덤프 다운로드  
   — ConfigMap에 넣지 않음 (256Ki annotation 한도)
3. 테이블 수 < `minTables`(기본 20) 이면 import, 아니면 skip

```bash
kubectl -n aniverse get job aniverse-db-restore
kubectl -n aniverse logs job/aniverse-db-restore -c restore
```

## 덤프 갱신

`data/aniverse_backup.sql` 을 main에 머지하면 Job이 다음 sync부터 그 URL을 받습니다.  
브랜치 덤프로 시험하려면 values의 `sqlUrl` 을 해당 ref raw URL로 바꿉니다.

## destroy 후 전체 복구 순서

1. Terraform apply  
2. Argo sync → DB Job SQL 복구 + 앱  
3. Sync media → S3  
4. `curl -sI https://aniverse.my/health/`

관련: [static-s3.md](./static-s3.md), infra `docs/eks-start-stop.md`
