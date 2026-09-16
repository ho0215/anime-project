# Local Docker 가이드 (현우 · 로컬 완성 1단계)

## 빠른 시작

```bash
cp .env.docker.example .env
docker compose up --build
```

- 앱: http://127.0.0.1:8000/
- 헬스: http://127.0.0.1:8000/health/  → `OK`
- DB: localhost:3307 (호스트에서 접속할 때)

컨테이너끼리 `db:3306` 이 막히는 환경(일부 CI/에이전트)에서는:

```bash
COMPOSE_DB_HOST=host.docker.internal COMPOSE_DB_PORT=3307 docker compose up --build
```

종료:

```bash
docker compose down
# 볼륨까지 삭제: docker compose down -v
```

## 이미지만 빌드

```bash
docker build -t aniverse:local .
```

## CI

- `.github/workflows/docker-build.yml` — PR/`cursor/**` 는 **빌드만**, `main`(또는 수동 실행)은 **ECR push**
- 인증: OIDC 권장 (`AWS_ROLE_ARN` + `AWS_USE_OIDC=true`) / 없으면 Access Key fallback
- 자세한 설정: [ecr-manual-push.md](./ecr-manual-push.md)
- 배포: ECR 이미지 → Helm (`deploy/helm/aniverse`) / EKS

## 태그 규칙

| 태그 | 의미 |
|------|------|
| `sha-<12자>` | 커밋 SHA (재현용, 권장) |
| `ref-<브랜치>` | 브랜치 참고용 |
| `local` | 로컬 compose |
| `latest` | ECR 푸시 시 옵션 (운영은 sha 권장) |

ECR 예: `123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/aniverse:sha-abc123def456`

## 다음에 할 일 (AWS)

1. ~~ECR 수동 push~~ / ~~Actions ECR push~~ — [ecr-manual-push.md](./ecr-manual-push.md)
2. 서이: EKS · Ingress · 노드 ECR pull
3. 윤주: DB StatefulSet / Helm 이미지 URL
4. 현우: Argo CD가 `deploy/k8s` (또는 Helm) sync
