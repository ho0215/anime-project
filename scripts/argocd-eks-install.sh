#!/usr/bin/env bash
# EKS에 Argo CD 설치 + aniverse-eks Application 등록 (실전 GitOps)
#
# 사전: kubectl → aniverse-eks, cluster-admin
#
#   ./scripts/argocd-eks-install.sh
#   SYNC=true ./scripts/argocd-eks-install.sh   # Application sync 까지
#
# 시크릿(DJANGO_SECRET_KEY/DB_PASSWORD/DB_ROOT_PASSWORD)은 External Secrets
# Operator가 AWS Secrets Manager에서 직접 동기화한다(docs/external-secrets.md,
# anime-project-infra). 이 스크립트는 더 이상 live Secret을 읽어 Helm
# parameter로 재주입하지 않음 — Application manifest 그대로 apply.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARGO_NS=argocd
ARGO_VERSION="${ARGO_VERSION:-v2.14.15}"
INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGO_VERSION}/manifests/install.yaml"
APP_MANIFEST="${ROOT}/deploy/argocd/application-eks-helm.yaml"
SYNC="${SYNC:-true}"

need() { command -v "$1" >/dev/null || { echo "$1 필요" >&2; exit 1; }; }
need kubectl
need python3

# Desired syncOptions — never include ServerSideApply (terminatingReplicas ComparisonError)
SYNC_OPTS_JSON='["CreateNamespace=true","RespectIgnoreDifferences=true"]'

sanitize_app_spec() {
  # kubectl apply 는 syncOptions 배열에서 ServerSideApply 를 안 지울 수 있음 → JSON replace 강제
  echo "==> Sanitize Application syncOptions (strip ServerSideApply) + ignoreDifferences"
  kubectl -n "${ARGO_NS}" patch application aniverse-eks --type=json -p="[
    {\"op\":\"replace\",\"path\":\"/spec/syncPolicy/syncOptions\",\"value\":${SYNC_OPTS_JSON}}
  ]" || true

  # ignoreDifferences 도 live 에 구버전(terminatingReplicas 없음)이 남을 수 있어 파일 기준으로 재적용
  local ign_patch
  ign_patch="$(python3 - "${APP_MANIFEST}" <<'PY'
import json, sys, yaml
with open(sys.argv[1], encoding="utf-8") as f:
    doc = yaml.safe_load(f)
ign = doc.get("spec", {}).get("ignoreDifferences") or []
print(json.dumps({"spec": {"ignoreDifferences": ign}}))
PY
)"
  kubectl -n "${ARGO_NS}" patch application aniverse-eks --type=merge -p "${ign_patch}" || true
}

cancel_operation() {
  kubectl -n "${ARGO_NS}" patch application aniverse-eks --type=json \
    -p='[{"op":"remove","path":"/operation"}]' 2>/dev/null || true
}

trigger_apply_sync() {
  local why="$1"
  echo "==> Trigger apply sync (${why})"
  cancel_operation
  kubectl -n "${ARGO_NS}" annotate application aniverse-eks \
    argocd.argoproj.io/refresh=hard --overwrite 2>/dev/null || true
  kubectl -n "${ARGO_NS}" patch application aniverse-eks --type merge -p \
    "{\"operation\":{\"initiatedBy\":{\"username\":\"argocd-eks-install\"},\"sync\":{\"revision\":\"HEAD\",\"syncStrategy\":{\"apply\":{\"force\":false}},\"syncOptions\":[\"CreateNamespace=true\",\"RespectIgnoreDifferences=true\"]}}}" \
    || true
}

dump_app_diagnostics() {
  kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.conditions}' 2>/dev/null; echo
  kubectl -n "${ARGO_NS}" get app aniverse-eks \
    -o jsonpath='{.status.operationState.phase} {.status.operationState.message}' 2>/dev/null; echo
  echo "syncOptions=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.spec.syncPolicy.syncOptions}' 2>/dev/null || true)"
  kubectl -n "${ARGO_NS}" get app aniverse-eks \
    -o jsonpath='{range .status.resources[*]}{.kind}/{.name} sync={.status} health={.health.status}{"\n"}{end}' \
    2>/dev/null | head -40 || true
  kubectl -n aniverse get pods,ingress,job 2>/dev/null || true
}

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

echo "==> Apply Application aniverse-eks"
kubectl apply -f "${APP_MANIFEST}"
sanitize_app_spec

if [ "${SYNC}" = "true" ]; then
  trigger_apply_sync "initial — client-side apply, no SSA"

  # ComparisonError 가 한 번 뜨면 SSA 잔존/스키마 이슈 → sanitize 후 1회 재시도
  # Missing 고착 시 예전엔 ~8분 대기 → 짧게 끊고 helm fallback
  REMEDIATED=0
  MISSING_STREAK=0
  MAX_WAIT="${ARGO_SYNC_MAX_WAIT:-12}"   # 12 * 5s ≈ 1분
  EARLY_MISSING="${ARGO_SYNC_EARLY_MISSING:-3}"  # Missing 연속 N회면 즉시 중단
  echo "==> Wait for Synced (max ~$((MAX_WAIT * 5))s); Missing ${EARLY_MISSING}회 연속이면 즉시 helm fallback"
  for i in $(seq 1 "${MAX_WAIT}"); do
    SYNC_ST=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
    HEALTH=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")
    MISSING_N=$(kubectl -n "${ARGO_NS}" get app aniverse-eks \
      -o jsonpath='{range .status.resources[*]}{.health.status}{"\n"}{end}' 2>/dev/null \
      | grep -c '^Missing$' || true)
    echo "  [$i/${MAX_WAIT}] sync=${SYNC_ST} health=${HEALTH} missing_resources=${MISSING_N}"
    # Ingress ALB 전 Progressing 은 정상. Job/리소스 Missing 만 실패로 본다.
    # OutOfSync + Healthy + Missing=0 → 이미지 태그 drift 등. 페이지 장애 아님 → OK 로 통과.
    if [ "${MISSING_N}" = "0" ]; then
      if [ "${HEALTH}" = "Healthy" ] || [ "${HEALTH}" = "Progressing" ]; then
        if [ "${SYNC_ST}" = "Synced" ]; then
          echo "  OK: Synced with health=${HEALTH} (no Missing resources)"
        else
          echo "  OK: health=${HEALTH} missing=0 (sync=${SYNC_ST} — image drift 등, 장애 아님)"
        fi
        break
      fi
    fi

    if [ "${HEALTH}" = "Missing" ] || [ "${MISSING_N}" != "0" ]; then
      MISSING_STREAK=$((MISSING_STREAK + 1))
    else
      MISSING_STREAK=0
    fi
    if [ "${MISSING_STREAK}" -ge "${EARLY_MISSING}" ]; then
      echo "  --- Missing ${MISSING_STREAK}회 연속 — 대기 중단, helm fallback ---"
      dump_app_diagnostics
      break
    fi

    COND=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.conditions[*].type}' 2>/dev/null || echo "")
    LIVE_OPTS=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.spec.syncPolicy.syncOptions}' 2>/dev/null || echo "")
    if echo "${COND}" | grep -q ComparisonError || echo "${LIVE_OPTS}" | grep -q ServerSideApply; then
      if [ "${REMEDIATED}" -eq 0 ]; then
        echo "  --- ComparisonError / ServerSideApply residue — remediating once ---"
        dump_app_diagnostics
        sanitize_app_spec
        trigger_apply_sync "after ComparisonError remediation"
        REMEDIATED=1
        MISSING_STREAK=0
        sleep 3
        continue
      fi
      echo "  --- ComparisonError persists after remediation — dump & continue to helm fallback ---"
      dump_app_diagnostics
      break
    fi

    if [ $((i % 4)) -eq 0 ]; then
      echo "  --- diagnostics ---"
      dump_app_diagnostics
    fi
    sleep 5
  done

  SYNC_ST=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
  HEALTH=$(kubectl -n "${ARGO_NS}" get app aniverse-eks -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")
  MISSING_N=$(kubectl -n "${ARGO_NS}" get app aniverse-eks \
    -o jsonpath='{range .status.resources[*]}{.health.status}{"\n"}{end}' 2>/dev/null \
    | grep -c '^Missing$' || true)
  if [ "${MISSING_N}" != "0" ] || { [ "${HEALTH}" != "Healthy" ] && [ "${HEALTH}" != "Progressing" ]; }; then
    echo "WARN: still sync=${SYNC_ST} health=${HEALTH} missing=${MISSING_N} — helm fallback / 수동 sync 필요할 수 있음" >&2
    dump_app_diagnostics
    kubectl -n "${ARGO_NS}" get app aniverse-eks -o yaml | sed -n '/^status:/,$p' | head -80 || true
  elif [ "${SYNC_ST}" != "Synced" ]; then
    echo "INFO: health=${HEALTH} missing=0 but sync=${SYNC_ST} (Deployment image drift 가능 — docker-build Argo sync 가 맞춤)" >&2
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
