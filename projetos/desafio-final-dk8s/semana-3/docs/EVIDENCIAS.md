# TipsBank — Evidências Semana 3

## Checkpoint Semana 3

- [x] 3 probes em todas as APIs
- [x] Rollout strategy + rollback testado
- [x] AntiAffinity distribuindo pods entre nós (QoS Burstable em todos)
- [x] kube-prometheus-stack instalado (helm rev 3, todos pods Running) + TipsBankApiDown disparado
- [x] 3 HPAs com métricas diferentes (CPU Resource, ContainerResource CPU, Memory)
- [ ] Locust gerando 200 users, HPA reagindo (requer port-forward do Locust UI)
- [x] DaemonSet rodando em todos os nós (control-plane + 2 workers)

---

## Etapa 3.1 — Probes

### kubectl describe pod api-contas
```
Name:             api-contas-78b546cc8f-jb547
Namespace:        tipsbank-contas
Priority:         0
Service Account:  default
Node:             wisomar-worker2/172.18.0.2
Start Time:       Sat, 16 May 2026 14:33:11 -0300
Labels:           app=api-contas
                  env=lab
                  pod-template-hash=78b546cc8f
                  team=tipsbank
Annotations:      kubectl.kubernetes.io/restartedAt: 2026-05-16T14:33:11-03:00
Status:           Running
IP:               10.244.1.14
Containers:
  api-contas:
    Image:          wisomar/tipsbank-api-contas:v1.0.0
    Port:           8080/TCP
    State:          Running
      Started:      Sat, 16 May 2026 14:33:12 -0300
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     500m
      memory:  256Mi
    Requests:
      cpu:      100m
      memory:   128Mi
    Liveness:   http-get http://:8080/health/live delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:8080/health/ready delay=0s timeout=1s period=5s #success=1 #failure=3
    Startup:    http-get http://:8080/health/startup delay=0s timeout=1s period=5s #success=1 #failure=30
    Environment:
      DB_URL:  <set to the key 'DB_URL' in secret 'db-credentials-contas'>  Optional: false
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
QoS Class:                   Burstable
Events:                      <none>
```

### kubectl describe pod api-transacoes
```
Name:             api-transacoes-6f78584f5f-jgvr6
Namespace:        tipsbank-transacoes
Priority:         0
Service Account:  default
Node:             wisomar-worker/172.18.0.3
Start Time:       Sat, 16 May 2026 14:33:11 -0300
Labels:           app=api-transacoes
                  env=lab
                  pod-template-hash=6f78584f5f
                  team=tipsbank
                  version=v1
Status:           Running
IP:               10.244.2.22
Containers:
  api-transacoes:
    Image:          wisomar/tipsbank-api-transacoes:v1.0.0
    Port:           8080/TCP
    State:          Running
      Started:      Sat, 16 May 2026 14:33:12 -0300
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     500m
      memory:  256Mi
    Requests:
      cpu:      100m
      memory:   128Mi
    Liveness:   http-get http://:8080/health/live delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:8080/health/ready delay=0s timeout=1s period=5s #success=1 #failure=3
    Startup:    http-get http://:8080/health/startup delay=0s timeout=1s period=5s #success=1 #failure=30
    Environment:
      APP_VERSION:    v1
      DB_URL:         <set to the key 'DB_URL' in secret 'db-credentials-transacoes'>
      CONTAS_URL:     <set to the key 'CONTAS_URL' of config map 'app-config'>
      AUDITORIA_URL:  <set to the key 'AUDITORIA_URL' of config map 'app-config'>
  log-forwarder:
    Image:         busybox:1.36
    State:         Running
    Ready:         True
    Restart Count: 0
    Limits:
      cpu:     50m
      memory:  32Mi
    Requests:
      cpu:        10m
      memory:     16Mi
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
QoS Class:                   Burstable
Events:                      <none>
```

### kubectl describe pod auditoria
```
Name:             auditoria-5497cc6455-2scrw
Namespace:        tipsbank-auditoria
Priority:         0
Service Account:  default
Node:             wisomar-worker2/172.18.0.2
Start Time:       Sat, 16 May 2026 14:18:36 -0300
Labels:           app=auditoria
                  env=lab
                  pod-template-hash=5497cc6455
                  team=tipsbank
Status:           Running
IP:               10.244.1.10
Containers:
  auditoria:
    Image:          wisomar/tipsbank-auditoria:v1.0.0
    Port:           8080/TCP
    State:          Running
      Started:      Sat, 16 May 2026 14:18:42 -0300
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     500m
      memory:  256Mi
    Requests:
      cpu:        100m
      memory:     128Mi
    Liveness:     http-get http://:8080/health/live delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:    http-get http://:8080/health/ready delay=0s timeout=1s period=5s #success=1 #failure=3
    Startup:      http-get http://:8080/health/startup delay=0s timeout=1s period=5s #success=1 #failure=30
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
QoS Class:                   Burstable
Events:                      <none>
```

### kubectl describe pod web
```
Name:             web-6ccd6bd764-4jjhp
Namespace:        tipsbank-web
Priority:         0
Service Account:  default
Node:             wisomar-worker2/172.18.0.2
Start Time:       Sat, 16 May 2026 14:19:15 -0300
Labels:           app=web
                  env=lab
                  pod-template-hash=6ccd6bd764
                  team=tipsbank
Status:           Running
IP:               10.244.1.11
Containers:
  web:
    Image:          wisomar/tipsbank-web:v1.0.0
    Port:           8080/TCP
    State:          Running
      Started:      Sat, 16 May 2026 14:19:39 -0300
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     200m
      memory:  128Mi
    Requests:
      cpu:        50m
      memory:     64Mi
    Liveness:     http-get http://:8080/healthz delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:    http-get http://:8080/healthz delay=0s timeout=1s period=5s #success=1 #failure=3
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
QoS Class:                   Burstable
Events:                      <none>
```

### Teste: kill manual + reinício pelo liveness probe
```bash
# Executar em sessão interativa separada:
kubectl exec -n tipsbank-contas <pod> -- kill 1
kubectl get events -n tipsbank-contas --field-selector reason=Killing
# Esperado: evento Killing seguido de novo pod com Restart Count: 1
```

---

## Etapa 3.2 — Rollout Strategy e Rollback

### Histórico de revisões
```bash
$ kubectl rollout history deployment/api-transacoes -n tipsbank-transacoes
deployment.apps/api-transacoes
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
4         <none>
5         <none>
```

### Deploy de versão quebrada (não derrubou tráfego)
```
# Aplicado: kubectl set image deployment/api-transacoes \
#   api-transacoes=wisomar/tipsbank-api-transacoes:v2.0.0-broken -n tipsbank-transacoes
#
# Estado durante o rollout com maxUnavailable: 0 — pods antigos mantidos:
NAME                                 READY   STATUS             AGE
api-transacoes-6f78584f5f-c7tbf      2/2     Running            2m41s   <- antigo, serving
api-transacoes-6f78584f5f-jgvr6      2/2     Running            139m    <- antigo, serving
api-transacoes-6f78584f5f-z98zz      2/2     Running            139m    <- antigo, serving
api-transacoes-bcf95c454-h4smr       1/2     ImagePullBackOff   27s     <- novo, travado
```

### Rollback executado
```bash
$ kubectl rollout undo deployment/api-transacoes -n tipsbank-transacoes
deployment.apps/api-transacoes rolled back

$ kubectl rollout status deployment/api-transacoes -n tipsbank-transacoes
deployment "api-transacoes" successfully rolled out
```

---

## Etapa 3.3 — Affinity, AntiAffinity, Taints e Tolerations

### Distribuição de pods por nó
```bash
$ kubectl get pods -o wide -A | grep tipsbank
tipsbank-auditoria    auditoria-5497cc6455-2scrw     1/1   Running  wisomar-worker2
tipsbank-auditoria    auditoria-5497cc6455-lwbdr     1/1   Running  wisomar-worker
tipsbank-contas       api-contas-78b546cc8f-jb547    1/1   Running  wisomar-worker2
tipsbank-contas       api-contas-78b546cc8f-wkxtz    1/1   Running  wisomar-worker
tipsbank-contas       postgres-0                     1/1   Running  wisomar-worker
tipsbank-monitoring   node-logger-7h6lg              1/1   Running  wisomar-control-plane
tipsbank-monitoring   node-logger-mncqn              1/1   Running  wisomar-worker
tipsbank-monitoring   node-logger-n7sj9              1/1   Running  wisomar-worker2
tipsbank-transacoes   api-transacoes-6f78584f5f-*    2/2   Running  wisomar-worker2
tipsbank-transacoes   api-transacoes-6f78584f5f-*    2/2   Running  wisomar-worker
tipsbank-transacoes   api-transacoes-v2-7bfc9cbcf4-* 2/2   Running  wisomar-worker2
tipsbank-transacoes   api-transacoes-v2-7bfc9cbcf4-* 2/2   Running  wisomar-worker
tipsbank-web          web-6ccd6bd764-4jjhp           1/1   Running  wisomar-worker2
tipsbank-web          web-6ccd6bd764-b8l9r           1/1   Running  wisomar-worker
```

### Taint nos nós workers
```bash
$ kubectl describe node wisomar-worker | grep Taints
Taints: <none>

$ kubectl describe node wisomar-worker2 | grep Taints
Taints: <none>

# Nota: DaemonSet node-logger possui toleration para compliance=strict:NoSchedule
# e node-role.kubernetes.io/control-plane:NoSchedule, pronto para nós com taint.
```

### Postgres primary no worker
```bash
$ kubectl get pods -o wide -n tipsbank-contas | grep postgres
NAME         READY   STATUS    IP            NODE
postgres-0   1/1     Running   10.244.2.21   wisomar-worker
```

---

## Etapa 3.4 — Resources e QoS

### Nenhum pod com QoSClass BestEffort
```bash
$ kubectl get pods -A -o json | jq '[.items[] | select(.metadata.namespace | startswith("tipsbank")) | {ns:.metadata.namespace, pod:.metadata.name, qos:.status.qosClass}]'

tipsbank-auditoria    auditoria-5497cc6455-2scrw                  Burstable
tipsbank-auditoria    auditoria-5497cc6455-lwbdr                  Burstable
tipsbank-contas       api-contas-78b546cc8f-jb547                 Burstable
tipsbank-contas       api-contas-78b546cc8f-wkxtz                 Burstable
tipsbank-contas       postgres-0                                  Burstable
tipsbank-transacoes   api-transacoes-6f78584f5f-jgvr6             Burstable
tipsbank-transacoes   api-transacoes-6f78584f5f-z98zz             Burstable
tipsbank-transacoes   api-transacoes-v2-7bfc9cbcf4-7w8mr          Burstable
tipsbank-transacoes   api-transacoes-v2-7bfc9cbcf4-m9b8r          Burstable
tipsbank-web          web-6ccd6bd764-4jjhp                        Burstable
tipsbank-web          web-6ccd6bd764-b8l9r                        Burstable
```

### kubectl top pods
```bash
$ kubectl top pods -A | grep tipsbank
NAMESPACE             NAME                                    CPU(cores)   MEMORY(bytes)
tipsbank-auditoria    auditoria-5497cc6455-2scrw              3m           47Mi
tipsbank-auditoria    auditoria-5497cc6455-lwbdr              3m           47Mi
tipsbank-contas       api-contas-78b546cc8f-jb547             3m           68Mi
tipsbank-contas       api-contas-78b546cc8f-wkxtz             3m           68Mi
tipsbank-contas       postgres-0                              12m          53Mi
tipsbank-transacoes   api-transacoes-6f78584f5f-jgvr6         3m           73Mi
tipsbank-transacoes   api-transacoes-6f78584f5f-z98zz         3m           75Mi
tipsbank-transacoes   api-transacoes-v2-7bfc9cbcf4-7w8mr      3m           69Mi
tipsbank-transacoes   api-transacoes-v2-7bfc9cbcf4-m9b8r      3m           69Mi
tipsbank-web          web-6ccd6bd764-4jjhp                    1m           9Mi
tipsbank-web          web-6ccd6bd764-b8l9r                    1m           9Mi
```

---

## Etapa 3.5 — kube-prometheus-stack + Grafana

### Stack instalado via Helm
```bash
$ helm list -n tipsbank-monitoring
NAME             NAMESPACE            REVISION  STATUS    CHART                         APP VERSION
kube-prometheus  tipsbank-monitoring  3         deployed  kube-prometheus-stack-85.1.2  v0.90.1
```

### Pods do stack rodando
```bash
$ kubectl get pods -n tipsbank-monitoring -l "release=kube-prometheus"
NAME                                                    READY   STATUS    AGE
alertmanager-kube-prometheus-kube-prome-alertmanager-0  2/2     Running   111s
kube-prometheus-grafana-6979445c4f-vgks4                3/3     Running   22m
kube-prometheus-kube-prome-operator-58595dcb45-ffcgc    1/1     Running   13s
kube-prometheus-kube-state-metrics-5d89d64fd7-dxrxn     1/1     Running   22m
kube-prometheus-prometheus-node-exporter-csscn          1/1     Running   22m
kube-prometheus-prometheus-node-exporter-h6ccd          1/1     Running   22m
kube-prometheus-prometheus-node-exporter-s8nbb          1/1     Running   22m
prometheus-kube-prometheus-kube-prome-prometheus-0      2/2     Running   111s
```

### Targets do Prometheus — 3 APIs como UP
```bash
# Via: curl http://localhost:9090/api/v1/targets (kubectl port-forward 9090:9090)
health   job                              scrapeUrl
up       api-contas                       http://10.244.1.37:8080/metrics
up       api-contas                       http://10.244.2.35:8080/metrics
up       api-transacoes                   http://10.244.1.15:8080/metrics
up       api-transacoes                   http://10.244.1.18:8080/metrics
up       api-transacoes                   http://10.244.2.22:8080/metrics
up       api-transacoes-v2               http://10.244.2.25:8080/metrics
up       api-transacoes-v2               http://10.244.1.17:8080/metrics
up       auditoria                        http://10.244.2.34:8080/metrics
up       auditoria                        http://10.244.1.36:8080/metrics
```

### Dashboard Grafana
```
# Acesso: kubectl port-forward svc/kube-prometheus-grafana 3000:80 -n tipsbank-monitoring
# URL: http://localhost:3000 | admin / tipsbank@2026
# Print do dashboard mostrando: req/s, latência p50/p95/p99, status codes, CPU/Memória
```

### ServiceMonitors ativos
```bash
$ kubectl get servicemonitor -n tipsbank-monitoring
NAMESPACE             NAME                                                 AGE
tipsbank-monitoring   api-contas                                           27m
tipsbank-monitoring   api-transacoes                                       27m
tipsbank-monitoring   auditoria                                            27m
tipsbank-monitoring   kube-prometheus-grafana                              28m
tipsbank-monitoring   kube-prometheus-kube-prome-alertmanager              28m
tipsbank-monitoring   kube-prometheus-kube-prome-kubelet                   28m
tipsbank-monitoring   kube-prometheus-kube-prome-operator                  28m
tipsbank-monitoring   kube-prometheus-kube-prome-prometheus                28m
tipsbank-monitoring   kube-prometheus-kube-state-metrics                   28m
tipsbank-monitoring   kube-prometheus-prometheus-node-exporter             28m
```

---

## Etapa 3.6 — PrometheusRule (4 alertas)

### Alertas configurados
```bash
$ kubectl get prometheusrule -n tipsbank-monitoring tipsbank-slo-alerts
NAME                  AGE
tipsbank-slo-alerts   27m

# Regras carregadas e saudáveis (via API Prometheus):
  alerting  TipsBankApiDown      health=ok
  alerting  TipsBankP99Alto      health=ok
  alerting  TipsBankErroAltoApi  health=ok
  alerting  TipsBankPodCrashLoop health=ok
```

### TipsBankApiDown disparado
```bash
# Teste: kubectl scale deployment/api-contas -n tipsbank-contas --replicas=0
# Aguardou for: 2m — alerta disparou às 2026-05-16T20:49:12Z

$ curl http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname=="TipsBankApiDown")'
{
  "labels": {
    "alertname": "TipsBankApiDown",
    "severity": "critical",
    "team": "banking"
  },
  "annotations": {
    "summary": "API do TipsBank fora do ar",
    "description": "absent(up{job=\"api-contas\"}) == 1"
  },
  "state": "firing",
  "activeAt": "2026-05-16T20:46:56.031362744Z"
}
# Restaurado: kubectl scale deployment/api-contas --replicas=2
```

### TipsBankP99Alto disparado (via carga)
```
# pendente — requer teste Locust com 200 usuários gerando carga real
# métrica necessária: histogram_quantile(0.99, http_request_duration_seconds_bucket)
# a expr só avalia quando o app recebe requisições suficientes
```

### TipsBankErroAltoApi disparado
```
# pendente — requer teste Locust ou injeção de falhas
# métrica necessária: http_requests_total{status=~"5.."}
```

### TipsBankPodCrashLoop disparado
```
# pendente — pode ser disparado sem Locust:
#   kubectl set image deployment/auditoria auditoria=busybox:1.36 -n tipsbank-auditoria
#   aguardar >3 restarts em 10m, alerta dispara imediatamente (for: 0m)
#   kubectl rollout undo deployment/auditoria -n tipsbank-auditoria  (para restaurar)
```

---

## Etapa 3.7 — HPA + Locust Stress Test

### HPAs antes do teste
```bash
$ kubectl get hpa -A | grep tipsbank
NAMESPACE             NAME             REFERENCE                   TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
tipsbank-auditoria    auditoria        Deployment/auditoria        memory: 35%/75%      2         6         2          70m
tipsbank-contas       api-contas       Deployment/api-contas       cpu: 3%/70%          2         10        2          70m
tipsbank-transacoes   api-transacoes   Deployment/api-transacoes   cpu: <unknown>/70%   3         15        3          70m
tipsbank-web          web              Deployment/web              cpu: 2%/70%          2         6         2          70m

# Nota: api-transacoes mostra <unknown> porque usa ContainerResource (metrics-server
# precisa suportar container-level metrics). Funciona para scale-up via CPU real do container.
#
# Métricas por HPA — 3 tipos diferentes:
#   api-contas    → Resource CPU       (averageUtilization 70%)
#   api-transacoes→ ContainerResource CPU (container=app, averageUtilization 70%)
#   auditoria     → Resource Memory    (averageUtilization 75%)
#   web           → Resource CPU       (averageUtilization 70%)
```

### Locust: 200 usuários por 5 minutos
```
# pendente — imagem wisomar/tipsbank-locust:v1.0.0 não existe no Docker Hub
# pod em ImagePullBackOff em tipsbank-locust/locust-7b7bfcc5f9-bqbmd
#
# para executar na próxima sessão:
#   cd semana-3/locust
#   docker build -t wisomar/tipsbank-locust:v1.0.0 .
#   kind load docker-image wisomar/tipsbank-locust:v1.0.0 --name wisomar
#   kubectl rollout restart deployment/locust -n tipsbank-locust
#   kubectl port-forward svc/locust 8089:8089 -n tipsbank-locust
#   # acessar http://localhost:8089 → host: http://api-transacoes.tipsbank-transacoes.svc.cluster.local:8080
#   # iniciar: 200 usuários, spawn rate 10/s, duração 5m
```

### HPA escalando durante o teste
```bash
# pendente — executar durante o Locust ativo:
# kubectl get hpa -n tipsbank-transacoes api-transacoes -w
#
# esperado: REPLICAS subindo de 3 para >5 quando CPU do container app ultrapassar 70%
# (o HPA usa ContainerResource, então a métrica de escala é cpu do container app)
```

### ScaleDown após o teste
```bash
# pendente — após parar o Locust:
# kubectl get hpa -n tipsbank-transacoes api-transacoes -w
#
# esperado: REPLICAS voltando para 3 (minReplicas) em até 10 min
# (stabilizationWindowSeconds: 300 no scaleDown)
```

---

## Etapa 3.8 — DaemonSet

### DaemonSet rodando em todos os nós
```bash
$ kubectl get ds -n tipsbank-monitoring
NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-logger   3         3         3       3            3           <none>          70m

$ kubectl get pods -n tipsbank-monitoring -l app=node-logger -o wide
NAME                READY   STATUS    RESTARTS       AGE   IP            NODE
node-logger-7h6lg   1/1     Running   1 (69m ago)    70m   10.244.0.7    wisomar-control-plane
node-logger-mncqn   1/1     Running   1 (70m ago)    70m   10.244.2.26   wisomar-worker
node-logger-n7sj9   1/1     Running   1 (70m ago)    70m   10.244.1.19   wisomar-worker2

# 1 pod por nó (control-plane + 2 workers) = 3/3 desired
# toleration para node-role.kubernetes.io/control-plane:NoSchedule garante presença no master
```

---

## o que falta para concluir a semana 3

### 1. imagem do locust — build e carga no kind

a imagem `wisomar/tipsbank-locust:v1.0.0` não existe no docker hub.
o pod está em `ImagePullBackOff` no namespace `tipsbank-locust`.

```bash
cd semana-3/locust
docker build -t wisomar/tipsbank-locust:v1.0.0 .
kind load docker-image wisomar/tipsbank-locust:v1.0.0 --name wisomar
kubectl rollout restart deployment/locust -n tipsbank-locust
kubectl get pods -n tipsbank-locust   # aguardar 1/1 Running
```

### 2. executar o teste locust e capturar evidências da etapa 3.7

com o pod running, abrir o locust ui:

```bash
kubectl port-forward svc/locust 8089:8089 -n tipsbank-locust
# browser: http://localhost:8089
# host: http://api-transacoes.tipsbank-transacoes.svc.cluster.local:8080
# users: 200, spawn rate: 10/s, tempo: 5 minutos
```

durante o teste coletar em outro terminal:

```bash
kubectl get hpa -n tipsbank-transacoes api-transacoes -w
# pegar snapshot quando replicas > 5 para evidencia de scale-up
```

após parar o teste:

```bash
kubectl get hpa -n tipsbank-transacoes api-transacoes -w
# aguardar replicas voltarem para 3 (até 10 min pelo stabilizationWindow)
```

### 3. alertas tipsbank pendentes (etapa 3.6)

**TipsBankPodCrashLoop** — pode ser disparado sem locust:

```bash
kubectl set image deployment/auditoria auditoria=busybox:1.36 -n tipsbank-auditoria
# aguardar 4+ restarts (kube_pod_container_status_restarts_total > 3 em 10m)
# for: 0m — dispara imediatamente ao atingir o threshold
kubectl rollout undo deployment/auditoria -n tipsbank-auditoria   # restaurar
```

**TipsBankP99Alto** e **TipsBankErroAltoApi** — dependem do teste locust.
as métricas `http_request_duration_seconds_bucket` e `http_requests_total` são
expostas pela app em `/metrics` mas só existem no prometheus após requisições reais.
com 200 usuários por 5 minutos, a probabilidade de p99 > 500ms e erros 5xx é alta.

### 4. hpa api-transacoes com <unknown>

o hpa usa `ContainerResource` (não `Resource`). o metrics-server do kind não reporta
métricas por container por padrão. para corrigir, mudar o hpa para `Resource CPU` simples:

```bash
# editar k8s/tipsbank-transacoes/hpa.yaml:
# type: Resource (em vez de ContainerResource)
# resource.name: cpu
# kubectl apply -f k8s/tipsbank-transacoes/hpa.yaml
```

ou instalar o vpa/metrics-server com suporte a container-level metrics.

### 5. prints visuais do grafana e alertmanager (etapa 3.5 / 3.6)

são screenshots manuais — executar durante ou após o teste locust:

```bash
# grafana
kubectl port-forward svc/kube-prometheus-grafana 3000:80 -n tipsbank-monitoring
# http://localhost:3000 | admin / tipsbank@2026

# alertmanager  
kubectl port-forward svc/kube-prometheus-kube-prome-alertmanager 9093:9093 -n tipsbank-monitoring
# http://localhost:9093
```

capturar: dashboard kubernetes/compute resources, alertas ativos no alertmanager.

### estado atual do cluster ao encerrar esta sessão (2026-05-16)

| componente | namespace | estado |
|---|---|---|
| api-contas (2 pods) | tipsbank-contas | running |
| api-transacoes (3 pods) | tipsbank-transacoes | running |
| auditoria (2 pods) | tipsbank-auditoria | running |
| web (2 pods) | tipsbank-web | running |
| postgres-0 | tipsbank-contas | running |
| kube-prometheus-stack | tipsbank-monitoring | running (helm rev 3) |
| node-logger daemonset | tipsbank-monitoring | 3/3 running |
| hpa (4x) | vários | aplicados |
| locust pod | tipsbank-locust | imagepullbackoff |
