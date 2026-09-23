# DB SQL 자동 복구 (destroy → 재apply)

EKS MariaDB는 PVC라 **Terraform destroy 시 데이터가 사라집니다.**  
스키마·시드는 Git의 SQL 덤프로 다시 넣고, 사진 등은 S3 sync로 복구합니다.

## 덤프 위치 (어디로 넣나)

| 항목 | 값 |
|------|-----|
| 레포 경로 | `data/aniverse_backup.sql` (anime-project **main**) |
| Job이 받는 URL | `dbRestore.sqlUrl` → 기본 `https://raw.githubusercontent.com/ho0215/anime-project/main/data/aniverse_backup.sql` |
| values | `deploy/helm/aniverse/values-eks.yaml` → `dbRestore.enabled: true` |

로컬 Ubuntu / 예전 EC2에 파일을 두는 것이 아닙니다. **main에 머지된 raw URL** 만 Job이 curl 합니다.

## 자동 경로 (EKS)

Helm `dbRestore.enabled: true` (`values-eks.yaml`):

1. Argo sync 시 Job `aniverse-db-restore` 생성 (일반 Job, Sync hook 아님)
2. Job이 `dbRestore.sqlUrl` 에서 curl로 덤프 다운로드  
   — ConfigMap/Sync-hook 미사용 (annotation 한도·sync 정합)
3. Skip / Import 판정:
   - 테이블 ≥ `minTables`(20) **그리고** `anime_anime` 행 > 0 → **Skip**
   - 그 외 (빈 DB, 또는 migrate만 돌아 **빈 스키마**) → **SQL import**  
     (`DROP TABLE IF EXISTS` 덤프이므로 빈 스키마 위에도 안전)

```bash
kubectl -n aniverse get job aniverse-db-restore
kubectl -n aniverse logs job/aniverse-db-restore -c restore
```

로그에 기대하는 문구:

- 정상 복구: `Restore complete. table_count=… seed_rows=…` (`seed_rows` ≥ 1)
- 이미 데이터 있음: `Skip restore — schema + seed already present.`
- **문제였던 옛 문구**: `Skip restore — schema already present.` (테이블만 보고 Skip → 시드 미복구)

## 무엇을 돌리나 (Argo vs Verify)

| 목적 | 워크플로 (infra) | 비고 |
|------|------------------|------|
| **DB 시드만** 다시 넣기 | **Verify DB restore Job** | Job 삭제 → helm로 Job 재적용 → 로그 검증. `app_ref` 기본 `main` |
| 클러스터/ALB/HTTPS/전체 sync | **Argo CD on EKS** | DB만 필요하면 필수 아님 |
| 이미지·상품 파일 | **Sync media → S3** | SQL과 별개. SQL만 넣으면 썸네일 깨질 수 있음 |

DB만 비어 보이면 → Verify DB restore.  
사이트 자체/인증서/ALB 문제면 → Argo CD on EKS.

## destroy 후 전체 복구 순서

1. Terraform apply  
2. Argo sync (또는 Argo CD on EKS) → 앱 + (가능하면) DB Job  
3. **Verify DB restore** — 로그에 `Restore complete` + `seed_rows≥1` 확인  
   (migrate가 먼저 돌면 Job이 Skip 할 수 있었음 → 아래 트러블슈팅)
4. Sync media → S3  
5. `curl -sI https://aniverse.my/health/` · `/deal/` · `/works/` 에 목록 존재 확인

## 트러블슈팅

### 1) Actions는 초록인데 장터/창작이 비어 있음

| | |
|--|--|
| 증상 | Verify DB restore **success**, 사이트는 「등록된 … 없습니다」 |
| 확인 | Job 로그 `table_count=25` + `Skip restore` |
| 원인 | 웹 Pod `migrate`가 **빈 테이블**을 먼저 만듦 → 예전 Job은 테이블 수 ≥ 20만 보고 Skip (exit 0) |
| 조치 | Job이 `anime_anime` 시드 행도 봄 (시드 0이면 force import). anime-project #55 · infra #100 |
| 재실행 | Job 삭제 후 Verify 다시. **Complete Job은 자동 재실행 안 됨** |

### 2) 백업 파일을 레포에 넣었는데 반영 안 됨

| | |
|--|--|
| 원인 | (a) **main 미머지**라 raw URL이 옛 파일 (b) Job이 이미 Complete라 재실행 안 됨 (c) Skip |
| 조치 | main 머지 → `kubectl delete job aniverse-db-restore -n aniverse` 또는 Verify 워크플로 |

### 3) EC2에 SSH해서 mysql 하면 되나?

| | |
|--|--|
| 답 | **아님.** 앱 EC2/CodeDeploy는 EKS 전환 후 제거됨. DB는 **클러스터 안 MariaDB Pod + PVC** |
| 보이는 EC2 | NAT·EKS 워커뿐 — SSH로 복구하는 경로 아님 |
| 올바른 경로 | infra Actions (OIDC→EKS) 또는 Access Entry 있는 PC에서 `kubectl` |

### 4) Job이 Missing / Argo sync 멈춤 (과거)

| | |
|--|--|
| 원인 | Job에 sync-wave를 Ingress보다 뒤로 두면, ALB ADDRESS 전 Ingress=`Progressing`이라 다음 wave Job이 영구 Missing |
| 조치 | Job에 높은 sync-wave 두지 않음. DB ready는 Job 안 `mariadb-admin ping` |
| 참고 | anime-project Job chart 주석 · infra troubleshooting 2026-09-16 hook/ConfigMap 항목 |

### 5) SQL은 들어갔는데 이미지가 깨짐

| | |
|--|--|
| 원인 | media는 SQL이 아니라 **S3** |
| 조치 | infra **Sync media → S3** / `scripts/restore-s3-assets.sh` |

### 6) Verify가 예전 브랜치 chart를 씀

| | |
|--|--|
| 증상 | `APP_REF: cursor/db-restore-auto-8e41` 등 stale ref |
| 조치 | workflow_dispatch `app_ref=main` (또는 Variables `ANIME_APP_REF`). infra #100 |

## 덤프 갱신

로컬/구서버에서 mysqldump 후:

```bash
# 예: 앱 DB → 파일
mysqldump -u… -p… aniverse > data/aniverse_backup.sql
```

`data/aniverse_backup.sql` 을 **main에 머지** → Verify(또는 Job 재생성)로 클러스터에 반영.  
브랜치 덤프 시험: values `sqlUrl` 을 해당 ref raw URL로 변경.

관련: [static-s3.md](./static-s3.md), infra [eks-start-stop.md](https://github.com/ho0215/anime-project-infra/blob/main/docs/eks-start-stop.md), infra **전체 장애 로그** [troubleshooting-log.md](https://github.com/ho0215/anime-project-infra/blob/main/docs/troubleshooting-log.md)  
(계정 이관 · ACM PENDING · Argo Missing/SSA/sync-wave · Cancel · secrets · OutOfSync 등 2026-09-22~23 항목 포함)

