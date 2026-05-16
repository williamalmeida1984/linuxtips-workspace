# TipsBank — Evidências Semana 3

## Checkpoint Semana 3

- [ ] 3 probes em todas as APIs
- [ ] Rollout strategy + rollback testado
- [ ] AntiAffinity + Taints/Tolerations + QoS classes corretas
- [ ] kube-prometheus-stack + 4 alertas disparando
- [ ] 3 HPAs com métricas diferentes
- [ ] Locust gerando 200 users, HPA reagindo
- [ ] DaemonSet rodando em todos os workers

---

## Etapa 3.1 — Probes

### kubectl describe pod api-contas
```
# cole o output aqui
```

### kubectl describe pod api-transacoes
```
# cole o output aqui
```

### kubectl describe pod auditoria
```
# cole o output aqui
```

### kubectl describe pod web
```
# cole o output aqui
```

### Teste: kill manual + reinício pelo liveness probe
```bash
kubectl exec -n tipsbank-contas <pod> -- kill 1
kubectl get events -n tipsbank-contas --field-selector reason=Killing
# cole o output aqui
```

---

## Etapa 3.2 — Rollout Strategy e Rollback

### Histórico de revisões
```bash
kubectl rollout history deployment/api-transacoes -n tipsbank-transacoes
# cole o output aqui
```

### Deploy de versão quebrada (não derrubou tráfego)
```bash
# cole evidência aqui
```

### Rollback executado
```bash
kubectl rollout undo deployment/api-transacoes -n tipsbank-transacoes
# cole o output aqui
```

---

## Etapa 3.3 — Affinity, AntiAffinity, Taints e Tolerations

### Distribuição de pods por nó
```bash
kubectl get pods -o wide -A | grep tipsbank
# cole o output aqui
```

### Taint no nó de compliance
```bash
kubectl describe node k8s-w2 | grep Taints
# cole o output aqui
```

### Postgres primary e replica em nós diferentes
```bash
kubectl get pods -o wide -n tipsbank-contas | grep postgres
# cole o output aqui
```

---

## Etapa 3.4 — Resources e QoS

### Nenhum pod com QoSClass BestEffort
```bash
kubectl get pods -A -o json | jq '[.items[] | {ns: .metadata.namespace, pod: .metadata.name, qos: .status.qosClass}]'
# cole o output aqui
```

### kubectl top pods
```bash
kubectl top pods -A
# cole o output aqui
```

---

## Etapa 3.5 — kube-prometheus-stack + Grafana

### Targets do Prometheus
```bash
# Print do Prometheus UI mostrando targets das 3 APIs como UP
```

### Dashboard Grafana
```
# Print do dashboard mostrando: req/s, latência p50/p95/p99, status codes, CPU/Memória
```

### ServiceMonitors ativos
```bash
kubectl get servicemonitor -A
# cole o output aqui
```

---

## Etapa 3.6 — PrometheusRule (4 alertas)

### Alertas configurados
```bash
kubectl get prometheusrule -A
# cole o output aqui
```

### TipsBankApiDown disparado
```
# Print do Alertmanager com o alerta ativo
```

### TipsBankP99Alto disparado (via carga)
```
# Print do Alertmanager com o alerta ativo
```

### TipsBankErroAltoApi disparado
```
# Print do Alertmanager com o alerta ativo
```

### TipsBankPodCrashLoop disparado
```
# Print do Alertmanager com o alerta ativo
```

---

## Etapa 3.7 — HPA + Locust Stress Test

### HPAs antes do teste
```bash
kubectl get hpa -A
# cole o output aqui
```

### Locust: 200 usuários por 5 minutos
```
# Print da UI do Locust mostrando: usuários, req/s, falhas < 1%
```

### HPA escalando durante o teste
```bash
kubectl get hpa -A -w
# cole o output aqui (api-transacoes deve chegar a >5 réplicas)
```

### ScaleDown após o teste
```bash
# cole evidência de que as réplicas voltaram ao mínimo em até 10 min
```

---

## Etapa 3.8 — DaemonSet

### DaemonSet rodando em todos os workers
```bash
kubectl get ds -n tipsbank-monitoring
kubectl get pods -n tipsbank-monitoring -l app=node-logger -o wide
# cole o output aqui
```
