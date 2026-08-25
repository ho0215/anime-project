# Aniverse App — CI/CD 메모

인프라는 `anime-project-infra` 저장소 Terraform이 담당합니다.
이 저장소는 **앱 코드 CodeDeploy** 만 수행합니다.

## 배포 흐름

1. `anime-project-infra` 에서 Terraform Apply → ALB / ASG / RDS / S3 / CodeDeploy / **SSM endpoints** 생성
2. Apply Output 의 `deploy_bucket_name` 을 이 저장소 Secret `S3_BUCKET_NAME` 에 등록
3. `main` 또는 `cursor/terraform-cicd-automation` 푸시 → `.github/workflows/deploy.yml` → S3 zip 업로드 → CodeDeploy

## GitHub Secrets (anime-project)

| Name | 필수 | 설명 |
|------|------|------|
| `AWS_ACCESS_KEY_ID` | ✅ | CodeDeploy/S3/SSM 용 |
| `AWS_SECRET_ACCESS_KEY` | ✅ | |
| `S3_BUCKET_NAME` | ✅ | Terraform output `deploy_bucket_name` |
| `GEMINI_API_KEY` | AI 챗봇 | Google AI Studio 키. 배포 후 SSM으로 EC2 `.env`에 주입 |

인프라 저장소에도 `TF_VAR_GEMINI_API_KEY` 를 넣으면 **신규 EC2** user_data `.env`에 포함됩니다.
이미 떠 있는 인스턴스는 앱 배포 워크플로의 SSM inject 단계를 쓰세요.

## GitHub Variables (선택)

| Name | 기본값 | 설명 |
|------|--------|------|
| `CODE_DEPLOY_APP_NAME` | `aniverse-app` | Terraform 과 동일해야 함 |
| `CODE_DEPLOY_GROUP_NAME` | `aniverse-deployment-group` | Terraform 과 동일해야 함 |

## EC2 런타임

Launch Template user_data 가 다음을 준비합니다.

- `amazon-ssm-agent` (SSM 접속)
- `default-libmysqlclient-dev` 등 **mysqlclient 빌드 의존성**
- nginx 임시 `/health/` (CodeDeploy 전 ALB unhealthy 방지)
- `/etc/aniverse.env` + systemd unit 파일

CodeDeploy `install_dependencies.sh` 는 apt를 다시 확인하고 `mysql_config` 존재 여부를 검사한 뒤 venv/pip를 수행합니다.
`start_server.sh` 는 **Daphne (ASGI)** 를 systemd (`aniverse.service`) 로 재시작합니다. (거래 채팅 WebSocket `/ws/` 지원)

### DB SQL 복원

커밋 메시지에 `[restore-db]` 를 넣거나 Actions `workflow_dispatch` 에서 `restore_db=true` 로 실행하면
배포 성공 후 SSM으로 `scripts/restore_db.sh` → `data/aniverse_backup.sql` 을 RDS에 적재합니다.

수동:
```bash
# SSM 접속 후
sudo bash /home/ubuntu/aniverse/scripts/restore_db.sh
```

### AI 챗봇 ("서버와 통신할 수 없습니다")

원인 후보:
1. CSRF 쿠키 없음 (홈에서 익명 사용자) → 최신 `chatbot.html` + `ensure_csrf_cookie` 로 해결
2. `GEMINI_API_KEY` 미설정 → Secret 등록 후 재배포(SSM inject)

### SSM 접속 (infra 저장소 스크립트)

```bash
# anime-project-infra 에서
ASG_NAME=aniverse-asg ./scripts/ssm-connect.sh
```

### 과거 라이브러리 오류 대응

증상: CodeDeploy 중 `pip install mysqlclient` 실패 (`mysql_config` / `MySQL.h` not found)

원인: EC2에 MySQL 클라이언트 개발 패키지가 없었음

조치: user_data + `install_dependencies.sh` 양쪽에
`default-libmysqlclient-dev build-essential pkg-config python3-dev` 설치 및 `mysql_config` preflight 검사
