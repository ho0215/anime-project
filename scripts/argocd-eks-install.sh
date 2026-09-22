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
# REQUIRE_LIVE_SECRETS=true(기본): live Secret 없으면 중단 (values-eks 빈 secrets + required)
APP_PATCHED="${OUT_DIR}/application-eks-helm.patched.yaml"
REQUIRE_LIVE_SECRETS="${REQUIRE_LIVE_SECRETS:-true}"
python3 - "${APP_MANIFEST}" "${APP_PATCHED}" "${REQUIRE_LIVE_SECRETS}" <<'PY'
import base64, json, subprocess, sys, yaml

src, dst, require = sys.argv[1], sys.argv[2], sys.argv[3].lower() in ("1", "true", "yes")
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
            if not val:
                continue
            params.append({"name": f"secrets.{key}", "value": val})
            print(f"  helm param secrets.{key} ← live secret", flush=True)
except subprocess.CalledProcessError:
    data = {}
    print("  (no live aniverse-app-secrets)", flush=True)

needed = {"secrets.DJANGO_SECRET_KEY", "secrets.DB_PASSWORD", "secrets.DB_ROOT_PASSWORD"}
have = {p["name"] for p in params}
missing = needed - have
if missing and require:
    print(
        "ERROR: missing live secrets for: "
        + ", ".join(sorted(missing))
        + "\n  Create them once, e.g.:\n"
        "  kubectl -n aniverse create secret generic aniverse-app-secrets \\\n"
        "    --from-literal=DJANGO_SECRET_KEY=... \\\n"
        "    --from-literal=DB_PASSWORD=... \\\n"
        "    --from-literal=DB_ROOT_PASSWORD=...\n"
        "  Or set REQUIRE_LIVE_SECRETS=false (lab only).",
        file=sys.stderr,
        flush=True,
    )
    sys.exit(1)
if missing and not require:
    print(f"  WARN: missing {sorted(missing)} — chart render may fail on empty values-eks secrets", flush=True)

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
  echo "==> Trigger sync (full apply — not hook-only)"
  # hook:{} 만 쓰면 Hook sync strategy 로 돌아가며 리소스가 Missing/OutOfSync 에 오래 남을 수 있음
  kubectl -n "${ARGO_NS}" patch application aniverse-eks --type merge -p \
    '{"operation":{"initiatedBy":{"username":"argocd-eks-install"},"sync":{"revision":"HEAD","syncStrategy":{"apply":{"force":false}},"syncOptions":["CreateNamespace=true","RespectIgnoreDifferences=true","ServerSideApply=true"]}}}' \
    || true

  echo "==> Wait for Synced/Healthy (up to ~5m)"
  for i in $(seq 1 60); do
    SYNC_ST=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
    HEALTH=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")
    echo "  [$i] sync=${SYNC_ST} health=${HEALTH}"
    if [ "${SYNC_ST}" = "Synced" ] && [ "${HEALTH}" = "Healthy" ]; then
      break
    fi
    # 12회마다(약 1분) 원인 덤프
    if [ $((i % 12)) -eq 0 ]; then
      echo "  --- diagnostics ---"
      kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.conditions}' 2>/dev/null; echo
      kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.operationState.phase} {.status.operationState.message}' 2>/dev/null; echo
      kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{range .status.resources[*]}{.kind}/{.name} sync={.status} health={.health.status}{"\n"}{end}' 2>/dev/null | head -40 || true
      kubectl -n aniverse get pods,ingress 2>/dev/null || true
    fi
    sleep 5
  done

  SYNC_ST=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
  HEALTH=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")
  if [ "${SYNC_ST}" != "Synced" ] || [ "${HEALTH}" != "Healthy" ]; then
    echo "WARN: still sync=${SYNC_ST} health=${HEALTH} — helm fallback / 수동 sync 필요할 수 있음" >&2
    kubectl -n "${ARGO_NS}" get app aniverse-eks -o yaml | sed -n '/^status:/,$p' | head -80 || true
  fi
fi

echo
echo "---- status ----"
kubectl -n "${ARGO_NS}" get app aniverse-eks -o wide || true
kubectl -n aniverse get pods 2>/dev/null || true
echo
echo "UI: kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo "    https://127.0.0.1:8080  (admin / initial secret)"
echo "GitOps: deploy/helm/aniverse + values-eks.yaml"
