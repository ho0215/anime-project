# Static → S3 (nginx 없이)

목표: CSS/JS/이미지를 **S3**에서 주고, 앱은 **Daphne만** 노출  
(`ALB → Pod:8000`, 브라우저 → S3 URL).

## 동작

`AWS_STORAGE_BUCKET_NAME` 이 있으면:

| 구분 | 백엔드 | URL |
|------|--------|-----|
| media (default) | `S3Boto3Storage` | 스토리지 `.url` |
| **staticfiles** | `S3StaticStorage` | `https://{bucket}.s3.{region}.amazonaws.com/static/` |

버킷이 비면 예전처럼 로컬 `staticfiles/` (개발용).

## 한 번 올리기 (현우 PC / CI)

스크립트는 **로컬 collectstatic → `aws s3 sync`** 입니다.  
(Django `S3StaticStorage`로 바로 올리면 파일마다 `HeadObject`라 랩에서 매우 느림.)

```bash
cd anime-project
source .venv/bin/activate   # 없으면: python3 -m venv .venv && pip install -r requirements.txt

# 실제 버킷 (수동 생성한 이름). Terraform 적용 후면 output 값을 쓸 것.
export AWS_STORAGE_BUCKET_NAME=aniverse-static-679583587966-ap-northeast-2
export AWS_S3_REGION_NAME=ap-northeast-2

./scripts/collectstatic-s3.sh
aws s3 ls "s3://${AWS_STORAGE_BUCKET_NAME}/static/" | head
```

브라우저에서 sample URL(스크립트 출력)이 200인지 확인.

## K8s / Helm

ConfigMap(또는 values)에:

```yaml
AWS_STORAGE_BUCKET_NAME: "<static_bucket_name>"
AWS_S3_REGION_NAME: ap-northeast-2
```

- **읽기:** 버킷 public-read(또는 CloudFront)면 Pod에 S3 읽기 권한 없어도 페이지 static 로드 가능  
- **쓰기(collectstatic):** CI/노트북에서 하거나, 나중에 IRSA로 Pod/`Job`에서 실행  
- 랩에서 `RUN_COLLECTSTATIC=true`로 Pod 기동 시 collectstatic 하면 **자격 증명 없으면 실패** → 기본은 CI/스크립트 권장

## Media (DB 복구 후 사진 안 보일 때)

DB 덤프에는 `goods_images/…`, `works_images/…` **경로만** 있고, S3 객체는 별도입니다.  
버킷을 비우거나 새로 만든 뒤 SQL만 넣으면 페이지 HTML은 S3 URL을 찍지만 **403/미존재**가 납니다.

로컬(또는 CI)에서 레포 `media/` 를 버킷 루트로 올립니다:

```bash
export STATIC_BUCKET_NAME=aniverse-static-679583587966-ap-northeast-2
export AWS_REGION=ap-northeast-2
./scripts/sync_media_to_s3.sh
```

SQL 자동 복구는 [db-restore.md](./db-restore.md). infra 레포 Actions **Sync media → S3** (`workflow_dispatch` / 해당 워크플로 push) 로도 동일하게 동기화할 수 있습니다.

## 남은 것

| 항목 | 담당 | 상태 |
|------|------|------|
| EKS Pod IRSA (업로드/media put) | 서이/현우 | Helm SA + TF `aniverse-web-s3-irsa` (apply 필요) |
| ALB Ingress | 서이 | 완료 |
| Helm values에 버킷명 반영·시크릿 | 윤주 values / 현우 연동 | 버킷 values-eks / secrets는 Argo params |
