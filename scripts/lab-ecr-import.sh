#!/usr/bin/env bash
# 랩 워커(containerd)에 ECR 이미지를 넣는 도우미.
#
# 새 Docker(containerd image store)는 `docker save`가 레이어 없이
# 수 KB tar만 만드는 경우가 있어, 기본 경로는 워커에서 `ctr images pull` 입니다.
#
# 사용:
#   ./scripts/lab-ecr-import.sh latest
#   ./scripts/lab-ecr-import.sh sha-abc123def456
#   WORKERS="ho0215@wk1 ho0215@wk2" ./scripts/lab-ecr-import.sh latest
set -euo pipefail

REGION="${AWS_REGION:-ap-northeast-2}"
ACCOUNT="${AWS_ACCOUNT_ID:-841535407395}"
REPO="${ECR_REPOSITORY:-aniverse}"
TAG="${1:-latest}"
REGISTRY="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
REMOTE="${REGISTRY}/${REPO}:${TAG}"
WORKERS="${WORKERS:-ho0215@wk1 ho0215@wk2}"

echo "==> ECR auth password"
PASS="$(aws ecr get-login-password --region "${REGION}")"
if [ -z "${PASS}" ]; then
  echo "failed to get ECR password" >&2
  exit 1
fi

echo "==> image: ${REMOTE}"
echo
echo "---- 워커에서 직접 pull (권장) ----"
for w in ${WORKERS}; do
  echo "ssh ${w} 'sudo ctr -n k8s.io images pull -u AWS:\$PASS ${REMOTE}'"
done
echo
echo "한 줄로 (cp1에서 실행, PASS 전달):"
echo "  PASS=\$(aws ecr get-login-password --region ${REGION})"
for w in ${WORKERS}; do
  cat <<EOF
  ssh ${w} "sudo ctr -n k8s.io images pull -u AWS:\${PASS} ${REMOTE}"
EOF
done

# 선택: cp1에서 원격 워커에 바로 pull (SSH 가능하면)
if [ "${LAB_ECR_PUSH:-}" = "1" ]; then
  echo
  echo "==> LAB_ECR_PUSH=1 — ssh로 워커에 ctr pull 실행"
  for w in ${WORKERS}; do
    echo "-- ${w}"
    ssh -o BatchMode=yes "${w}" \
      "sudo ctr -n k8s.io images pull -u AWS:${PASS} ${REMOTE}"
    ssh -o BatchMode=yes "${w}" \
      "sudo ctr -n k8s.io images ls | grep -E '${REPO}|${ACCOUNT}' || true"
  done
fi

echo
echo "---- pull 확인 (각 워커) ----"
echo "  sudo ctr -n k8s.io images ls | grep aniverse"
echo
echo "---- cp1 apply ----"
echo "  kubectl apply -k deploy/k8s/overlays/lab-ecr"
echo "  kubectl -n aniverse delete pod -l app=aniverse-web"
echo "  kubectl -n aniverse get pods -o wide -w"
echo
echo "참고: docker save 경로는 containerd image store에서 깨질 수 있어 사용하지 않습니다."
echo "      자동 ssh pull: LAB_ECR_PUSH=1 WORKERS=\"ho0215@wk1 ho0215@wk2\" $0 ${TAG}"
