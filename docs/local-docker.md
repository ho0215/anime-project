# Local Docker 가이드 (현우 · 로컬 완성 1단계)

## 빠른 시작

```bash
cp .env.docker.example .env
docker compose up --build
```

- 앱: http://127.0.0.1:8000/
- 헬스: http://127.0.0.1:8000/health/
- DB: localhost:3307 (호스트에서 접속할 때)

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

- `.github/workflows/docker-build.yml` — PR/push 시 이미지 **빌드만** (ECR push는 시크릿 연결 후)
- 기존 `deploy.yml` (CodeDeploy)는 v1용으로 유지

## 태그 규칙

| 태그 | 의미 |
|------|------|
| `sha-<12자>` | 커밋 SHA (재현용, 권장) |
| `ref-<브랜치>` | 브랜치 참고용 |
| `local` | 로컬 compose |
| `latest` | ECR 푸시 시 옵션 (운영은 sha 권장) |

ECR 예: `123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/aniverse:sha-abc123def456`

## 다음에 할 일 (AWS)

1. ECR 리포지토리 생성
2. Actions에 ECR push 활성화
3. Argo CD가 `deploy/k8s` (또는 Helm) sync
4. 서이: EKS · Ingress / 윤주: DB StatefulSet 차트와 합치기
