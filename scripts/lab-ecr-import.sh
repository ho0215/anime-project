#!/usr/bin/env bash
# ECR → docker pull → tar → (안내) 워커 ctr import
# 사용: ./scripts/lab-ecr-import.sh [tag]
# 예:   ./scripts/lab-ecr-import.sh latest
#       ./scripts/lab-ecr-import.sh sha-abc123def456
set -euo pipefail

REGION="${AWS_REGION:-ap-northeast-2}"
ACCOUNT="${AWS_ACCOUNT_ID:-679583587966}"
REPO="${ECR_REPOSITORY:-aniverse}"
TAG="${1:-latest}"
REGISTRY="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
REMOTE="${REGISTRY}/${REPO}:${TAG}"
TAR="${TMPDIR:-/tmp}/aniverse-ecr-${TAG//\//-}.tar"

echo "==> ECR login (${REGION})"
aws ecr get-login-password --region "${REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

echo "==> docker pull ${REMOTE}"
docker pull "${REMOTE}"

echo "==> docker save → ${TAR}"
docker save -o "${TAR}" "${REMOTE}"
ls -lh "${TAR}"

echo
echo "OK — 이미지 tar 준비됨."
echo "워커(wk1/wk2)에 복사 후 import 예:"
echo "  scp ${TAR} ubuntu@wk1:~/"
echo "  scp ${TAR} ubuntu@wk2:~/"
echo "  # 각 워커에서:"
echo "  sudo ctr -n k8s.io images import ~/(basename ${TAR})"
echo "  sudo ctr -n k8s.io images ls | grep aniverse"
echo
echo "그다음 cp1에서:"
echo "  cd ~/Desktop/anime-project   # clone 경로"
echo "  # 태그 맞추기 (latest 아니면):"
echo "  (cd deploy/k8s/overlays/lab-ecr && kustomize edit set image aniverse=${REMOTE})"
echo "  kubectl apply -k deploy/k8s/overlays/lab-ecr"
echo "  kubectl -n aniverse get pods -o wide -w"
