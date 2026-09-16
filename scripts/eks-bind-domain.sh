#!/usr/bin/env bash
# EKS Ingress ALB ← aniverse.my (Route53 + ACM)
#
# 사전: kubectl → aniverse-eks, aws iac-admin, helm release aniverse 배포됨
#
#   ./scripts/eks-bind-domain.sh
#   ./scripts/eks-bind-domain.sh aniverse.my
set -euo pipefail

DOMAIN="${1:-aniverse.my}"
WWW="www.${DOMAIN}"
REGION="${AWS_REGION:-ap-northeast-2}"
NS="${NAMESPACE:-aniverse}"
INGRESS_NAME="${INGRESS_NAME:-aniverse-web}"

need() { command -v "$1" >/dev/null || { echo "$1 필요" >&2; exit 1; }; }
need aws
need kubectl
need helm

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

1) AWS 콘솔에서 ${DOMAIN} 퍼블릭 호스팅 영역 생성
2) 가비아(등록기관) NS 를 Route53 네임서버로 위임
3) 다시: ./scripts/eks-bind-domain.sh

또는 가비아에서 A/ALIAS(또는 CNAME)를 직접 EKS ALB 로 지정:
  ${ALB_DNS}
EOF
  exit 1
fi
echo "==> Route53 zone: ${HOSTED_ZONE_ID}"

ALB_HOSTED_ZONE="$(aws elbv2 describe-load-balancers \
  --region "${REGION}" \
  --query "LoadBalancers[?DNSName=='${ALB_DNS}'].CanonicalHostedZoneId | [0]" \
  --output text)"
if [ -z "${ALB_HOSTED_ZONE}" ] || [ "${ALB_HOSTED_ZONE}" = "None" ]; then
  # dualstack. 접두 없는 이름 / 이름 대소문자
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
)"
  echo "    UPSERT A ${name} → dualstack.${ALB_DNS}"
}

echo "==> DNS records"
upsert_alias "${DOMAIN}"
upsert_alias "${WWW}"

echo "==> ACM certificate (ISSUED)"
CERT_ARN="$(aws acm list-certificates --region "${REGION}" --certificate-statuses ISSUED \
  --query "CertificateSummaryList[?DomainName=='${DOMAIN}' || DomainName=='*.${DOMAIN}'].CertificateArn | [0]" \
  --output text)"
if [ -z "${CERT_ARN}" ] || [ "${CERT_ARN}" = "None" ]; then
  # SAN 에 포함된 인증서 검색
  for arn in $(aws acm list-certificates --region "${REGION}" --certificate-statuses ISSUED \
    --query 'CertificateSummaryList[].CertificateArn' --output text); do
    if aws acm describe-certificate --region "${REGION}" --certificate-arn "${arn}" \
      --query "Certificate.SubjectAlternativeNames[?@=='${DOMAIN}' || @=='${WWW}']" \
      --output text | grep -q .; then
      CERT_ARN="${arn}"
      break
    fi
  done
fi

if [ -z "${CERT_ARN}" ] || [ "${CERT_ARN}" = "None" ]; then
  echo "ISSUED ACM 없음 — DNS 검증 인증서 요청 (존에 CNAME 자동은 콘솔/terraform 권장)"
  CERT_ARN="$(aws acm request-certificate --region "${REGION}" \
    --domain-name "${DOMAIN}" \
    --subject-alternative-names "${WWW}" \
    --validation-method DNS \
    --query CertificateArn --output text)"
  echo "    requested: ${CERT_ARN}"
  echo "    콘솔에서 DNS 검증 레코드 추가 후 ISSUED 되면 다시 이 스크립트 실행"
  echo "    (DNS A 레코드는 이미 EKS ALB 로 붙여 둠 — HTTP 로 먼저 접속 가능)"
  CERT_ARN=""
else
  echo "    ${CERT_ARN}"
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "==> Helm upgrade (host=${DOMAIN})"
EXTRA=()
if [ -n "${CERT_ARN}" ]; then
  EXTRA+=(
    --set-string "ingress.annotations.alb\.ingress\.kubernetes\.io/certificate-arn=${CERT_ARN}"
    --set-string 'ingress.annotations.alb\.ingress\.kubernetes\.io/listen-ports=[{"HTTP":80},{"HTTPS":443}]'
    --set-string 'ingress.annotations.alb\.ingress\.kubernetes\.io/ssl-redirect=443'
    --set-string config.USE_HTTPS=True
  )
else
  EXTRA+=(--set-string config.USE_HTTPS=False)
fi

# secrets 는 기존 Secret 유지 (helm이 비우지 않도록 재지정하지 않음 — --reuse-values)
helm upgrade aniverse "${ROOT}/deploy/helm/aniverse" \
  -n "${NS}" \
  -f "${ROOT}/deploy/helm/aniverse/values-eks.yaml" \
  --reuse-values \
  --set-string "ingress.host=${DOMAIN}" \
  --set-string "config.DJANGO_ALLOWED_HOSTS=${DOMAIN},${WWW},*" \
  --set-string "config.DJANGO_CSRF_TRUSTED_ORIGINS=https://${DOMAIN},https://${WWW},http://${DOMAIN},http://${WWW}" \
  "${EXTRA[@]}"

kubectl -n "${NS}" rollout status deploy/aniverse-web --timeout=180s || true

echo
echo "OK"
echo "  DNS:  https://${DOMAIN}  (전파 1~5분)"
echo "  check: dig +short ${DOMAIN}"
echo "  curl:  curl -sI http://${DOMAIN}/health/"
if [ -n "${CERT_ARN}" ]; then
  echo "  https: curl -sI https://${DOMAIN}/health/"
fi
