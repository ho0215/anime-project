#!/usr/bin/env bash
# 로컬에서 Aniverse 이미지를 빌드해 ECR에 수동 push 합니다.
# 사전: aws CLI 로그인 가능, Docker 실행 중, ECR 리포 존재
set -euo pipefail

REGION="${AWS_REGION:-ap-northeast-2}"
REPO_NAME="${ECR_REPOSITORY:-aniverse}"
IMAGE_LOCAL_TAG="${IMAGE_LOCAL_TAG:-aniverse:local}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
REMOTE="${REGISTRY}/${REPO_NAME}"

SHA_SHORT="$(git rev-parse --short=12 HEAD 2>/dev/null || echo manual)"
SHA_TAG="sha-${SHA_SHORT}"

echo "==> Account: ${ACCOUNT_ID}"
echo "==> Registry: ${REGISTRY}"
echo "==> Repo: ${REPO_NAME}"
echo "==> Tags: ${SHA_TAG}, latest"

# 리포 없으면 생성 (Terraform 적용 전 빠른 경로)
if ! aws ecr describe-repositories --repository-names "${REPO_NAME}" --region "${REGION}" >/dev/null 2>&1; then
  echo "==> Creating ECR repository: ${REPO_NAME}"
  aws ecr create-repository \
    --repository-name "${REPO_NAME}" \
    --region "${REGION}" \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256 >/dev/null
fi

echo "==> docker build"
docker build -t "${IMAGE_LOCAL_TAG}" -t "${REMOTE}:${SHA_TAG}" -t "${REMOTE}:latest" .

echo "==> ECR login"
aws ecr get-login-password --region "${REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

echo "==> docker push"
docker push "${REMOTE}:${SHA_TAG}"
docker push "${REMOTE}:latest"

echo
echo "OK — pushed:"
echo "  ${REMOTE}:${SHA_TAG}"
echo "  ${REMOTE}:latest"
echo
echo "K8s에서 pull 할 때 (프라이빗 ECR이면 노드에 pull 권한 필요):"
echo "  image: ${REMOTE}:${SHA_TAG}"
