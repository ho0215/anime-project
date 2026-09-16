#!/usr/bin/env bash
# EKS에 Argo CD 설치 + aniverse-eks Application 등록 (실전 GitOps)
#
# 사전: kubectl → aniverse-eks, cluster-admin
#
#   ./scripts/argocd-eks-install.sh
#   SYNC=true ./scripts/argocd-eks-install.sh   # Application sync 까지
#
# 이미 helm 으로 올라간 aniverse 가 있으면 Secret 값을 읽어
# Helm parameter 로 넣어 sync 시 랩 기본 비밀번호로 덮이지 않게 한다.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARGO_NS=argocd
ARGO_VERSION="${ARGO_VERSION:-v2.14.9}"
INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGO_VERSION}/manifests/install.yaml"
APP_MANIFEST="${ROOT}/deploy/argocd/application-eks-helm.yaml"
SYNC="${SYNC:-true}"
OUT_DIR="${OUT_DIR:-/tmp/argocd-eks}"
mkdir -p "${OUT_DIR}"

need() { command -v "$1" >/dev/null || { echo "$1 필요" >&2; exit 1; }; }
need kubectl
need python3

echo "==> kubectl context: $(kubectl config current-context 2>/dev/null || echo '?')"
kubectl cluster-info >/dev/null

echo "==> Create namespace ${ARGO_NS}"
kubectl apply -f "${ROOT}/deploy/argocd/namespace.yaml"

echo "==> Install Argo CD ${ARGO_VERSION}"
kubectl apply -n "${ARGO_NS}" -f "${INSTALL_URL}"

echo "==> Wait for Application CRD"
for _ in $(seq 1 90); do
  if kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
kubectl get crd applications.argoproj.io >/dev/null

echo "==> Wait for argocd-server"
kubectl -n "${ARGO_NS}" rollout status deployment/argocd-server --timeout=300s
kubectl -n "${ARGO_NS}" wait --for=condition=Available deployment/argocd-server --timeout=180s

echo "==> Initial admin password (if present):"
if kubectl -n "${ARGO_NS}" get secret argocd-initial-admin-secret >/dev/null 2>&1; then
  kubectl -n "${ARGO_NS}" get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d
  echo
else
  echo "(secret not ready yet)"
fi

# Live Secret → Helm parameters (avoid overwriting EKS passwords with values.yaml lab defaults)
APP_PATCHED="${OUT_DIR}/application-eks-helm.patched.yaml"
python3 - "${APP_MANIFEST}" "${APP_PATCHED}" <<'PY'
import base64, json, subprocess, sys, yaml

src, dst = sys.argv[1], sys.argv[2]
with open(src, encoding="utf-8") as f:
    doc = yaml.safe_load(f)

params = []
try:
    raw = subprocess.check_output(
        [
            "kubectl", "-n", "aniverse", "get", "secret", "aniverse-app-secrets",
            "-o", "json",
        ],
        stderr=subprocess.DEVNULL,
        text=True,
    )
    data = json.loads(raw).get("data") or {}
    for key in ("DJANGO_SECRET_KEY", "DB_PASSWORD", "DB_ROOT_PASSWORD"):
        if key in data:
            val = base64.b64decode(data[key]).decode("utf-8")
            params.append({"name": f"secrets.{key}", "value": val})
            print(f"  helm param secrets.{key} ← live secret", flush=True)
except subprocess.CalledProcessError:
    print("  (no live aniverse-app-secrets — chart default secrets will be used)", flush=True)

helm = doc.setdefault("spec", {}).setdefault("source", {}).setdefault("helm", {})
existing = {p.get("name"): p for p in helm.get("parameters") or [] if isinstance(p, dict)}
for p in params:
    existing[p["name"]] = p
helm["parameters"] = list(existing.values())

with open(dst, "w", encoding="utf-8") as f:
    yaml.safe_dump(doc, f, sort_keys=False, allow_unicode=True)
print(f"Wrote {dst}", flush=True)
PY

echo "==> Apply Application aniverse-eks"
kubectl apply -f "${APP_PATCHED}"

if [ "${SYNC}" = "true" ]; then
  echo "==> Trigger sync (prune=false via Application syncPolicy)"
  # Force a sync operation without argocd CLI
  kubectl -n "${ARGO_NS}" patch application aniverse-eks --type merge -p '{"operation":{"initiatedBy":{"username":"argocd-eks-install"},"sync":{"syncStrategy":{"hook":{}},"syncOptions":["CreateNamespace=true","RespectIgnoreDifferences=true"]}}}' || true

  echo "==> Wait for Synced/Healthy (up to ~5m)"
  for i in $(seq 1 60); do
    SYNC_ST=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
    HEALTH=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")
    echo "  [$i] sync=${SYNC_ST} health=${HEALTH}"
    if [ "${SYNC_ST}" = "Synced" ] && [ "${HEALTH}" = "Healthy" ]; then
      break
    fi
    sleep 5
  done
fi

echo
echo "---- status ----"
kubectl -n "${ARGO_NS}" get app aniverse-eks -o wide || true
kubectl -n aniverse get pods 2>/dev/null || true
echo
echo "UI: kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo "    https://127.0.0.1:8080  (admin / initial secret)"
echo "GitOps: deploy/helm/aniverse + values-eks.yaml"
