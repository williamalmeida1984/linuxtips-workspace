#!/usr/bin/env bash
# Constrói, escaneia e assina a imagem api-transacoes:v2.0.0 para o Canary da Semana 2.
set -euo pipefail

REGISTRY="${REGISTRY:-wisomar}"
APP="api-transacoes"
TAG="v2.0.0"
IMG="${REGISTRY}/tipsbank-${APP}:${TAG}"

cd "$(dirname "$0")/.."

echo "==> Build com APP_VERSION=v2"
docker build \
  --build-arg APP_VERSION=v2 \
  -t "${IMG}" \
  "apps/${APP}"

echo ""
echo "==> Trivy scan (0 HIGH/CRITICAL obrigatório)"
trivy image --severity HIGH,CRITICAL --exit-code 1 "${IMG}"

echo ""
echo "==> Push para Docker Hub"
docker push "${IMG}"

echo ""
echo "==> Assinatura Cosign (keyless OIDC)"
COSIGN_EXPERIMENTAL=1 cosign sign --yes "${IMG}"

echo ""
echo "==> Verificação"
COSIGN_EXPERIMENTAL=1 cosign verify "${IMG}" \
  --certificate-identity-regexp '.*' \
  --certificate-oidc-issuer-regexp '.*' > /dev/null && \
  echo "OK: ${IMG}"

echo ""
echo "==> Pronto. Aplique o manifest de canary:"
echo "    kubectl apply -f k8s/tipsbank-transacoes/deployment-v2.yaml"
echo "    kubectl apply -f k8s/tipsbank-transacoes/service-v2.yaml"
echo "    kubectl apply -f k8s/tipsbank-transacoes/ingress-canary.yaml"
