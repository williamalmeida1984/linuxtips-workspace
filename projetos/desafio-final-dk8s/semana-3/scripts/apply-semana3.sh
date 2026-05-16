#!/usr/bin/env bash
# Aplica todos os manifests da Semana 3 no cluster kubeadm.
# Pré-requisito: kubectl configurado e namespace tipsbank-monitoring criado.

set -euo pipefail

K8S="$(dirname "$0")/../k8s"

echo "=== [1/8] Métricas Server ==="
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system \
  --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' \
  2>/dev/null || true

echo "=== [2/8] Taint no nó de compliance ==="
echo "ATENÇÃO: Ajuste o nome do nó abaixo para o worker que deve ser isolado."
# kubectl taint nodes k8s-w2 compliance=strict:NoSchedule

echo "=== [3/8] Monitoring namespace + kube-prometheus-stack ==="
kubectl apply -f "$K8S/tipsbank-monitoring/namespace.yaml"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  -n tipsbank-monitoring \
  -f "$K8S/tipsbank-monitoring/kube-prometheus-values.yaml" \
  --wait --timeout=5m

echo "=== [4/8] Deployments com probes + resources + affinity ==="
kubectl apply -f "$K8S/tipsbank-contas/deployment.yaml"
kubectl apply -f "$K8S/tipsbank-contas/statefulset-postgres.yaml"
kubectl apply -f "$K8S/tipsbank-transacoes/deployment.yaml"
kubectl apply -f "$K8S/tipsbank-auditoria/deployment.yaml"
kubectl apply -f "$K8S/tipsbank-web/deployment.yaml"

echo "=== [5/8] HPAs ==="
kubectl apply -f "$K8S/tipsbank-contas/hpa.yaml"
kubectl apply -f "$K8S/tipsbank-transacoes/hpa.yaml"
kubectl apply -f "$K8S/tipsbank-auditoria/hpa.yaml"
kubectl apply -f "$K8S/tipsbank-web/hpa.yaml"

echo "=== [6/8] ServiceMonitors + PrometheusRule ==="
kubectl apply -f "$K8S/tipsbank-monitoring/servicemonitor-contas.yaml"
kubectl apply -f "$K8S/tipsbank-monitoring/servicemonitor-transacoes.yaml"
kubectl apply -f "$K8S/tipsbank-monitoring/servicemonitor-auditoria.yaml"
kubectl apply -f "$K8S/tipsbank-monitoring/prometheusrule.yaml"

echo "=== [7/8] Locust ==="
kubectl apply -f "$K8S/tipsbank-locust/namespace.yaml"
kubectl apply -f "$K8S/tipsbank-locust/deployment.yaml"
kubectl apply -f "$K8S/tipsbank-locust/service.yaml"
kubectl apply -f "$K8S/tipsbank-locust/ingress.yaml"

echo "=== [8/8] DaemonSet node-logger ==="
kubectl apply -f "$K8S/node/daemonset.yaml"

echo ""
echo "=== STATUS ==="
kubectl get pods -A -l team=banking
echo ""
kubectl get hpa -A
echo ""
kubectl get ds -n tipsbank-monitoring
echo ""
echo "Acesse: https://grafana.tipsbank.local  https://prometheus.tipsbank.local  https://locust.tipsbank.local"
