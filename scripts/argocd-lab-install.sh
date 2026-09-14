#!/usr/bin/env bash
# 랩(kubeadm)에 Argo CD 설치 + aniverse-lab Application 등록
# 사용 (cp1):
#   cd ~/Desktop/anime-project && ./scripts/argocd-lab-install.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARGO_NS=argocd
# 고정 버전 (재현용). 올리려면 태그만 변경.
ARGO_VERSION="${ARGO_VERSION:-v2.14.9}"
INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGO_VERSION}/manifests/install.yaml"

echo "==> kubectl context: $(kubectl config current-context 2>/dev/null || echo '?')"
kubectl cluster-info >/dev/null

echo "==> Create namespace ${ARGO_NS}"
kubectl apply -f "${ROOT}/deploy/argocd/namespace.yaml"

echo "==> Install Argo CD ${ARGO_VERSION}"
kubectl apply -n "${ARGO_NS}" -f "${INSTALL_URL}"

echo "==> Wait for argocd-server"
kubectl -n "${ARGO_NS}" rollout status deployment/argocd-server --timeout=180s
kubectl -n "${ARGO_NS}" wait --for=condition=Available deployment --all --timeout=180s 2>/dev/null || true

echo "==> Initial admin password:"
if kubectl -n "${ARGO_NS}" get secret argocd-initial-admin-secret >/dev/null 2>&1; then
  kubectl -n "${ARGO_NS}" get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d
  echo
else
  echo "(secret not ready yet — retry in a few seconds)"
fi

echo "==> Apply Application aniverse-lab"
kubectl apply -f "${ROOT}/deploy/argocd/application-lab-ecr.yaml"

echo
echo "---- next ----"
echo "1) ECR 이미지가 wk1/wk2 에 있어야 Pod Ready (ctr pull). 문서: docs/lab-k8s-ecr.md"
echo "2) UI:"
echo "   kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo "   https://127.0.0.1:8080  (user: admin / password 위)"
echo "3) 상태:"
echo "   kubectl -n argocd get app aniverse-lab"
echo "   kubectl -n aniverse get pods"
echo
echo "레포가 private 이면 Argo 에 Git 자격증명 필요 — docs/argocd-lab.md"
