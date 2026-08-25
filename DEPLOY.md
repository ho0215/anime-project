# Aniverse App — CI/CD 메모

인프라는 `anime-project-infra` 저장소 Terraform이 담당합니다.
이 저장소는 **앱 코드 CodeDeploy** 만 수행합니다.

## 배포 흐름

1. `anime-project-infra` 에서 Terraform Apply → ALB / ASG / RDS / S3 / CodeDeploy 생성
2. Apply Output 의 `deploy_bucket_name` 을 이 저장소 Secret `S3_BUCKET_NAME` 에 등록
3. `main` 푸시 → `.github/workflows/deploy.yml` → S3 zip 업로드 → CodeDeploy

## GitHub Secrets (anime-project)

| Name | 필수 | 설명 |
|------|------|------|
| `AWS_ACCESS_KEY_ID` | ✅ | CodeDeploy/S3 업로드용 |
| `AWS_SECRET_ACCESS_KEY` | ✅ | |
| `S3_BUCKET_NAME` | ✅ | Terraform output `deploy_bucket_name` |

## GitHub Variables (선택)

| Name | 기본값 | 설명 |
|------|--------|------|
| `CODE_DEPLOY_APP_NAME` | `aniverse-app` | Terraform 과 동일해야 함 |
| `CODE_DEPLOY_GROUP_NAME` | `aniverse-deployment-group` | Terraform 과 동일해야 함 |

## EC2 런타임

Launch Template user_data 가 `/etc/aniverse.env` 와 systemd `aniverse.service` 를 준비합니다.
CodeDeploy `install_dependencies.sh` / `start_server.sh` 는 Gunicorn을 **systemd** 로 재시작합니다.
