# Evidências — Semana 1

## Etapa 1.1 — Aplicação rodando localmente

### Listagem das contas seed (sem senha_hash)
curl http://localhost:8081/contas
[{"id":"11111111-1111-1111-1111-111111111111","titular":"Jeferson Fernando","documento":"12345678901","saldo":"9900.00"},
 {"id":"22222222-2222-2222-2222-222222222222","titular":"LinuxTips SA","documento":"98765432100","saldo":"600.00"}]

### Login correto (200)
curl -X POST http://localhost:8081/login -d '{"documento":"12345678901","senha":"giropops"}'
{"id":"11111111-...","titular":"Jeferson Fernando","saldo":"10000.00"}

### Login errado (401)
curl -X POST http://localhost:8081/login -d '{"documento":"12345678901","senha":"errada"}'
{"detail":"credenciais invalidas"}

### Transferência de R$100
{"status":"concluida","valor":"100.00"}

### Evento de auditoria
{"tipo":"transferencia","transacao_id":"4a05a475-...","valor":"100.00","versao_app":"v1"}

---

## Etapa 1.2 — Imagens Distroless, Trivy e Cosign

### Por que Distroless reduz vulnerabilidades
A imagem gcr.io/distroless/python3-debian12:nonroot não possui shell, package manager
nem ferramentas desnecessárias. Sem shell = sem execução de comandos arbitrários.
Sem apt/pip = sem instalação de pacotes maliciosos em runtime. UID 65532 (nonroot)
impede escalonamento de privilégios mesmo em caso de comprometimento do container.

### Trivy scan — 0 HIGH/CRITICAL (--ignore-unfixed)
wisomar/tipsbank-api-contas:v1.0.0     — 0 vulnerabilidades
wisomar/tipsbank-api-transacoes:v1.0.0 — 0 vulnerabilidades
wisomar/tipsbank-auditoria:v1.0.0      — 0 vulnerabilidades
wisomar/tipsbank-web:v1.0.0            — 0 vulnerabilidades

### Usuário não-root
docker inspect wisomar/tipsbank-api-contas:v1.0.0 | grep User → "65532"
docker inspect wisomar/tipsbank-web:v1.0.0 | grep User → "101"

### Cosign — assinaturas verificadas
cosign verify OK: wisomar/tipsbank-api-contas@sha256:eb5f7a05...
cosign verify OK: wisomar/tipsbank-api-transacoes@sha256:321ef7e8...
cosign verify OK: wisomar/tipsbank-auditoria@sha256:3e167180...
cosign verify OK: wisomar/tipsbank-web@sha256:f16fa8d9...

---

## Etapa 1.3 — Cluster kubeadm multi-node

### Nodes Ready
kubectl get nodes -o wide
NAME     STATUS   ROLES           AGE   VERSION    INTERNAL-IP
k8s-cp   Ready    control-plane   ...   v1.29.15   10.251.173.101
k8s-w1   Ready    <none>          ...   v1.29.15   10.251.173.98
k8s-w2   Ready    <none>          ...   v1.29.15   10.251.173.166

### Pods kube-system Running
calico-kube-controllers   1/1   Running
calico-node (x3)          1/1   Running
coredns (x2)              1/1   Running
etcd-k8s-cp               1/1   Running
kube-apiserver-k8s-cp     1/1   Running
kube-controller-manager   1/1   Running
kube-scheduler            1/1   Running

### Pod nginx no worker (não no CP)
kubectl run nginx --image=nginx
kubectl get pod nginx -o wide → NODE: k8s-w2

---

## Etapa 1.4 — Namespaces, Deployments e Services

### Pods Running
tipsbank-contas       api-contas (2/2)     Running
tipsbank-contas       postgres-0 (1/1)     Running
tipsbank-transacoes   api-transacoes (2/2) Running
tipsbank-auditoria    auditoria (2/2)      Running
tipsbank-web          web (2/2)            Running

### Transferência via port-forward
curl -X POST http://localhost:8082/transferencias -d '{...,"valor":100}'
{"status":"concluida","valor":"100.00"}

---

## Etapa 1.5 — ConfigMap, Secret e pod multicontainer

### 2 containers no pod
kubectl get pod api-transacoes-xxx -o yaml → containers: [api-transacoes, log-forwarder]

### Log estruturado no sidecar
kubectl logs -c log-forwarder api-transacoes-xxx
{"ts":"2026-05-13 23:38:34","level":"INFO","service":"api-transacoes","msg":"bootstrap versao=v1"}

### Variáveis externalizadas
- DATABASE_URL → secretKeyRef: db-credentials-transacoes
- API_CONTAS_URL → configMapKeyRef: app-config
- AUDITORIA_URL → configMapKeyRef: app-config
- CONTAS_URL → configMapKeyRef: app-config

---

## Etapa 1.6 — PV NFS para a auditoria

### PV e PVC Bound
kubectl get pv,pvc -A
pv-auditoria-nfs   5Gi   RWX   Bound   tipsbank-auditoria/pvc-auditoria

### 3 réplicas da auditoria
kubectl get pods -n tipsbank-auditoria
auditoria-xxx-1   1/1   Running
auditoria-xxx-2   1/1   Running
auditoria-xxx-3   1/1   Running

### Arquivo compartilhado no NFS
ls /srv/nfs/auditoria/
eventos-2026-05-13.jsonl

wc -l /srv/nfs/auditoria/eventos-2026-05-13.jsonl
11 eventos registrados pelas 3 réplicas no mesmo arquivo
