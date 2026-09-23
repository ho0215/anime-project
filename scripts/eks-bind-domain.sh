#!/usr/bin/env bash
# EKS Ingress ALB ← aniverse.my (Route53 + ACM HTTPS)
#
# 사전: kubectl → aniverse-eks, aws iac-admin, helm release aniverse 배포됨
#
#   ./scripts/eks-bind-domain.sh
#   ACM_CERT_ARN=arn:aws:acm:... ./scripts/eks-bind-domain.sh
#
# Terraform ACM을 재사용. PENDING이면 검증 CNAME을 Route53에 맞추고
# ISSUED까지 대기. 새 인증서를 함부로 만들지 않는다.
set -euo pipefail

DOMAIN="${1:-aniverse.my}"
WWW="www.${DOMAIN}"
REGION="${AWS_REGION:-ap-northeast-2}"
NS="${NAMESPACE:-aniverse}"
INGRESS_NAME="${INGRESS_NAME:-aniverse-web}"
# TODO(계정 이관): 새 계정 ACM — ISSUED 확인 후 사용. 오버라이드: ACM_CERT_ARN=...
DEFAULT_CERT_ARN="${ACM_CERT_ARN:-arn:aws:acm:ap-northeast-2:841535407395:certificate/da27663b-d716-4eaa-98ba-2ea5653bdb71}"
WAIT_SEC="${ACM_WAIT_SEC:-900}"
POLL_SEC="${ACM_POLL_SEC:-30}"

need() { command -v "$1" >/dev/null || { echo "$1 필요" >&2; exit 1; }; }
need aws
need kubectl
need helm
need python3

if [ -z "${DEFAULT_CERT_ARN}" ]; then
  echo "ACM_CERT_ARN 이 비어 있습니다 (새 계정 인증서 ARN 필요)" >&2
  exit 1
fi

echo "==> Ingress ALB hostname"
ALB_DNS="$(kubectl -n "${NS}" get ingress "${INGRESS_NAME}" \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
if [ -z "${ALB_DNS}" ]; then
  echo "Ingress ADDRESS 없음. kubectl -n ${NS} get ingress 확인" >&2
  exit 1
fi
echo "    ${ALB_DNS}"

HOSTED_ZONE_ID="$(aws route53 list-hosted-zones-by-name \
  --dns-name "${DOMAIN}." \
  --query "HostedZones[?Name=='${DOMAIN}.'].Id | [0]" \
  --output text 2>/dev/null || true)"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID##*/}"

if [ -z "${HOSTED_ZONE_ID}" ] || [ "${HOSTED_ZONE_ID}" = "None" ]; then
  cat >&2 <<EOF
Route53 호스팅 영역이 없습니다: ${DOMAIN}

1) Terraform apply (module.dns) 로 존 생성
2) 가비아 NS 를 terraform output route53_name_servers 로 위임
3) 다시: ./scripts/eks-bind-domain.sh
EOF
  exit 1
fi
echo "==> Route53 zone: ${HOSTED_ZONE_ID}"

ALB_HOSTED_ZONE="$(aws elbv2 describe-load-balancers \
  --region "${REGION}" \
  --query "LoadBalancers[?DNSName=='${ALB_DNS}'].CanonicalHostedZoneId | [0]" \
  --output text)"
if [ -z "${ALB_HOSTED_ZONE}" ] || [ "${ALB_HOSTED_ZONE}" = "None" ]; then
  ALB_HOSTED_ZONE="$(aws elbv2 describe-load-balancers --region "${REGION}" \
    --query "LoadBalancers[?contains(DNSName, 'k8s-aniverse')].CanonicalHostedZoneId | [0]" \
    --output text)"
fi
if [ -z "${ALB_HOSTED_ZONE}" ] || [ "${ALB_HOSTED_ZONE}" = "None" ]; then
  echo "ALB hosted zone id 조회 실패 — ALB DNS: ${ALB_DNS}" >&2
  exit 1
fi
echo "    ALB zone: ${ALB_HOSTED_ZONE}"

upsert_alias() {
  local name="$1"
  aws route53 change-resource-record-sets --hosted-zone-id "${HOSTED_ZONE_ID}" \
    --change-batch "$(cat <<EOF
{
  "Comment": "Point ${name} to EKS Ingress ALB",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "${name}",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "${ALB_HOSTED_ZONE}",
        "DNSName": "dualstack.${ALB_DNS}",
        "EvaluateTargetHealth": true
      }
    }
  }]
}
EOF
)" >/dev/null
  echo "    UPSERT A ${name} → dualstack.${ALB_DNS}"
}

echo "==> DNS records"
upsert_alias "${DOMAIN}"
upsert_alias "${WWW}"

cert_status() {
  aws acm describe-certificate --region "${REGION}" --certificate-arn "$1" \
    --query 'Certificate.Status' --output text 2>/dev/null || echo "MISSING"
}

find_cert_for_domain() {
  local status arn
  for status in ISSUED PENDING_VALIDATION; do
    for arn in $(aws acm list-certificates --region "${REGION}" --certificate-statuses "${status}" \
      --query 'CertificateSummaryList[].CertificateArn' --output text); do
      if aws acm describe-certificate --region "${REGION}" --certificate-arn "${arn}" \
        --query "Certificate.SubjectAlternativeNames[?@=='${DOMAIN}' || @=='${WWW}']" \
        --output text | grep -q .; then
        echo "${arn}"
        return 0
      fi
    done
  done
  return 1
}

upsert_acm_validation_records() {
  local arn="$1"
  echo "==> ACM DNS validation CNAMEs → Route53"
  ACM_ARN="${arn}" HOSTED_ZONE_ID="${HOSTED_ZONE_ID}" REGION="${REGION}" python3 <<'PY'
import json, os, subprocess, sys
arn = os.environ["ACM_ARN"]
zone = os.environ["HOSTED_ZONE_ID"]
region = os.environ["REGION"]
raw = subprocess.check_output([
    "aws", "acm", "describe-certificate",
    "--region", region, "--certificate-arn", arn,
    "--query", "Certificate.DomainValidationOptions", "--output", "json",
], text=True)
opts = json.loads(raw)
changes = []
for o in opts:
    rr = o.get("ResourceRecord") or {}
    if not rr.get("Name"):
        continue
    name = rr["Name"].rstrip(".") + "."
    value = rr["Value"].rstrip(".") + "."
    changes.append({
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": name,
            "Type": rr.get("Type", "CNAME"),
            "TTL": 60,
            "ResourceRecords": [{"Value": value}],
        },
    })
    print(f"    {name} → {value}")
if not changes:
    print("    (validation ResourceRecord 아직 없음 — 잠시 후 재시도)", file=sys.stderr)
    sys.exit(0)
batch = json.dumps({"Comment": "ACM DNS validation", "Changes": changes})
subprocess.check_call([
    "aws", "route53", "change-resource-record-sets",
    "--hosted-zone-id", zone, "--change-batch", batch,
], stdout=subprocess.DEVNULL)
PY
}

wait_issued() {
  local arn="$1" deadline status
  deadline=$((SECONDS + WAIT_SEC))
  while (( SECONDS < deadline )); do
    status="$(cert_status "${arn}")"
    echo "    status=${status}"
    if [ "${status}" = "ISSUED" ]; then
      return 0
    fi
    if [ "${status}" = "FAILED" ] || [ "${status}" = "VALIDATION_TIMED_OUT" ] || [ "${status}" = "MISSING" ]; then
      echo "ACM 실패: ${status}" >&2
      return 1
    fi
    sleep "${POLL_SEC}"
    upsert_acm_validation_records "${arn}" || true
  done
  echo "타임아웃: 아직 ${status:-unknown}. 나중에 다시 ./scripts/eks-bind-domain.sh" >&2
  return 1
}

echo "==> ACM certificate"
CERT_ARN=""
if [ -n "${DEFAULT_CERT_ARN}" ] && [ "$(cert_status "${DEFAULT_CERT_ARN}")" != "MISSING" ]; then
  CERT_ARN="${DEFAULT_CERT_ARN}"
  echo "    prefer: ${CERT_ARN} ($(cert_status "${CERT_ARN}"))"
else
  CERT_ARN="$(find_cert_for_domain || true)"
  if [ -n "${CERT_ARN}" ]; then
    echo "    found: ${CERT_ARN} ($(cert_status "${CERT_ARN}"))"
  fi
fi

if [ -z "${CERT_ARN}" ]; then
  echo "도메인 ACM 없음 — Terraform module.dns 또는 ACM_CERT_ARN 지정" >&2
  echo "새 인증서는 여기서 만들지 않음 (중복 PENDING 방지)." >&2
  exit 1
fi

STATUS="$(cert_status "${CERT_ARN}")"
if [ "${STATUS}" != "ISSUED" ]; then
  upsert_acm_validation_records "${CERT_ARN}"
  echo "==> waiting for ISSUED (up to ${WAIT_SEC}s) — 가비아 NS 가 Route53 이어야 함"
  dig +short NS "${DOMAIN}" || true
  wait_issued "${CERT_ARN}"
fi
echo "    ISSUED: ${CERT_ARN}"

echo "==> 중복 PENDING ACM 정리 힌트 (선택)"
aws acm list-certificates --region "${REGION}" --certificate-statuses PENDING_VALIDATION \
  --query "CertificateSummaryList[?DomainName=='${DOMAIN}'].CertificateArn" --output text \
| tr '\t' '\n' | while read -r arn; do
  [ -z "${arn}" ] && continue
  [ "${arn}" = "${CERT_ARN}" ] && continue
  echo "    삭제 후보: aws acm delete-certificate --certificate-arn ${arn}"
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "==> Helm upgrade (host=${DOMAIN}, HTTPS)"
OVERLAY="$(mktemp)"
trap 'rm -f "${OVERLAY}"' EXIT
cat > "${OVERLAY}" <<EOF
config:
  DJANGO_ALLOWED_HOSTS: "${DOMAIN},${WWW},*"
  DJANGO_CSRF_TRUSTED_ORIGINS: "https://${DOMAIN},https://${WWW},http://${DOMAIN},http://${WWW}"
  USE_HTTPS: "True"
ingress:
  host: ${DOMAIN}
  annotations:
    alb.ingress.kubernetes.io/certificate-arn: "${CERT_ARN}"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
EOF

# values-eks.yaml 의 secrets.* 는 빈 문자열(required). -f 로 넣으면
# --reuse-values 를 덮어써서 DJANGO_SECRET_KEY required 로 터짐.
# live Secret → --set-string 으로만 주입하고, 오버레이만 추가 merge.
DJANGO="$(kubectl -n "${NS}" get secret aniverse-app-secrets -o jsonpath='{.data.DJANGO_SECRET_KEY}' | base64 -d)"
DBPASS="$(kubectl -n "${NS}" get secret aniverse-app-secrets -o jsonpath='{.data.DB_PASSWORD}' | base64 -d)"
ROOTPASS="$(kubectl -n "${NS}" get secret aniverse-app-secrets -o jsonpath='{.data.DB_ROOT_PASSWORD}' | base64 -d)"
if [ -z "${DJANGO}" ] || [ -z "${DBPASS}" ] || [ -z "${ROOTPASS}" ]; then
  echo "aniverse-app-secrets 에 DJANGO/DB/ROOT 없음 — bind 전 Secret 시드 필요" >&2
  exit 1
fi

helm upgrade aniverse "${ROOT}/deploy/helm/aniverse" \
  -n "${NS}" \
  -f "${OVERLAY}" \
  --reuse-values \
  --set-string "secrets.DJANGO_SECRET_KEY=${DJANGO}" \
  --set-string "secrets.DB_PASSWORD=${DBPASS}" \
  --set-string "secrets.DB_ROOT_PASSWORD=${ROOTPASS}"

kubectl -n "${NS}" rollout status deploy/aniverse-web --timeout=180s || true

echo
echo "OK"
echo "  dig +short NS ${DOMAIN}"
echo "  curl -sI https://${DOMAIN}/health/"
echo "  (ALB 443 반영 1~3분)"
