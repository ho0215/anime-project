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

```bash
cd anime-project
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

export AWS_STORAGE_BUCKET_NAME=aniverse-static-ho0215-dev-2026-679583587966-ap-northeast-2
# Terraform output static_bucket_name 이 다르면 그 값 사용
export AWS_S3_REGION_NAME=ap-northeast-2

chmod +x scripts/collectstatic-s3.sh
./scripts/collectstatic-s3.sh
```

브라우저에서 아무 static URL이 200인지 확인.

## K8s / Helm

ConfigMap(또는 values)에:

```yaml
AWS_STORAGE_BUCKET_NAME: "<static_bucket_name>"
AWS_S3_REGION_NAME: ap-northeast-2
```

- **읽기:** 버킷 public-read(또는 CloudFront)면 Pod에 S3 읽기 권한 없어도 페이지 static 로드 가능  
- **쓰기(collectstatic):** CI/노트북에서 하거나, 나중에 IRSA로 Pod/`Job`에서 실행  
- 랩에서 `RUN_COLLECTSTATIC=true`로 Pod 기동 시 collectstatic 하면 **자격 증명 없으면 실패** → 기본은 CI/스크립트 권장

## EC2 v1

Instance profile로 S3 쓰던 환경이면 `collectstatic` 후 nginx `/static/` 대신 S3 URL을 쓰게 됨.  
nginx static location은 사실상 불필요해짐 (전환 확인 후 제거 가능).

## 남은 것 (혼자 아님)

| 항목 | 담당 |
|------|------|
| EKS Pod IRSA (업로드/media put) | 서이 |
| ALB Ingress | 서이 |
| Helm values에 버킷명 반영·시크릿 | 윤주 values / 현우 연동 |
