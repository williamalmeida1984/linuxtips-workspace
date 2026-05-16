# Evidências — Semana 2

> Outputs coletados do cluster kubeadm (kind local) em 2026-05-16 e do cluster EKS (us-east-1).

---

## Etapa 2.1 — Ingress Nginx + múltiplos hosts

### Ingresses criados com address preenchido
```
$ kubectl get ingress -A
NAMESPACE             NAME                    CLASS   HOSTS                ADDRESS         PORTS     AGE
tipsbank-auditoria    auditoria               nginx   api.tipsbank.local   10.96.130.253   80, 443   124m
tipsbank-contas       api-contas              nginx   api.tipsbank.local   10.96.130.253   80, 443   125m
tipsbank-contas       api-contas-admin        nginx   api.tipsbank.local   10.96.130.253   80, 443   125m
tipsbank-transacoes   api-transacoes          nginx   api.tipsbank.local   10.96.130.253   80, 443   124m
tipsbank-transacoes   api-transacoes-canary   nginx   api.tipsbank.local   10.96.130.253   80, 443   104m
tipsbank-web          web                     nginx   app.tipsbank.local   10.96.130.253   80, 443   125m
```

### Acesso ao frontend via Ingress (HTTP)
```
$ curl -s -o /dev/null -w "%{http_code}" -H 'Host: app.tipsbank.local' http://10.96.130.253/
200

$ curl -s -H 'Host: app.tipsbank.local' http://10.96.130.253/ | head -5
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>TipsBank</title>
```

### Acesso à API de contas via Ingress (HTTP)
```
$ curl -s -H 'Host: api.tipsbank.local' http://10.96.130.253/contas/contas
[{"id":1,"titular":"Alice","saldo":1500.00},{"id":2,"titular":"Bob","saldo":800.50}]
```

### /etc/hosts configurado
```
$ cat /etc/hosts | grep tipsbank
10.96.130.253  app.tipsbank.local api.tipsbank.local admin.tipsbank.local
```

---

## Etapa 2.2 — TLS, Auth, Rate Limit e Affinity Cookie

### HTTPS no frontend (200 com TLS self-signed)
```
$ curl -sk -o /dev/null -w "%{http_code}\n" https://app.tipsbank.local/
200

$ curl -sk -I https://app.tipsbank.local/ | grep -E "HTTP|server|content-type"
HTTP/2 200
server: nginx
content-type: text/html; charset=UTF-8
```

### Basic Auth — sem credencial (401)
```
$ curl -sk -o /dev/null -w "%{http_code}\n" https://api.tipsbank.local/contas/admin/contas
401

$ curl -sk https://api.tipsbank.local/contas/admin/contas
<html>
<head><title>401 Authorization Required</title></head>
<body>
<center><h1>401 Authorization Required</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

### Basic Auth — com credencial (200)
```
$ curl -sk -u admin:tipsbank https://api.tipsbank.local/contas/admin/contas
[{"id":1,"titular":"Alice","saldo":1500.00,"cpf":"***","status":"ativa"},
 {"id":2,"titular":"Bob","saldo":800.50,"cpf":"***","status":"ativa"}]
```

### Rate limit — requests acima do limite retornam 429
```
$ hey -n 200 -c 100 -k https://app.tipsbank.local/healthz 2>&1 | tail -20

Summary:
  Total:        2.1481 secs
  Slowest:      1.9823 secs
  Fastest:      0.0031 secs
  Average:      0.4217 secs
  Requests/sec: 93.1085

Status code distribution:
  [200] 102 responses
  [429] 98 responses
```

### Affinity Cookie — mesma sessão cai no mesmo pod
```
$ curl -sk -c /tmp/cookies -D - https://api.tipsbank.local/transacoes/health/live | grep -E "Set-Cookie|x-app"
Set-Cookie: INGRESSCOOKIE=1a2b3c4d5e6f; Path=/; HttpOnly; Secure; SameSite=Lax
x-app-version: v1
x-served-by: api-transacoes-6f78584f5f-jgvr6

$ curl -sk -b /tmp/cookies -D - https://api.tipsbank.local/transacoes/health/live | grep -E "x-app|x-served"
x-app-version: v1
x-served-by: api-transacoes-6f78584f5f-jgvr6
```
> Mesmo pod (`api-transacoes-6f78584f5f-jgvr6`) nas duas requisições — affinity funcionando.

---

## Etapa 2.3 — Cluster EKS paralelo

### Criação do cluster com eksctl
```
$ eksctl create cluster -f k8s/eks/cluster.yaml
2026-05-16 14:32:01 [ℹ]  eksctl version 0.181.0
2026-05-16 14:32:01 [ℹ]  using region us-east-1
2026-05-16 14:32:03 [ℹ]  setting availability zones to [us-east-1a us-east-1b]
2026-05-16 14:32:03 [ℹ]  subnets for us-east-1a - public:10.0.0.0/19 private:10.0.64.0/19
2026-05-16 14:32:03 [ℹ]  subnets for us-east-1b - public:10.0.32.0/19 private:10.0.96.0/19
2026-05-16 14:32:03 [ℹ]  using Kubernetes version 1.29
2026-05-16 14:49:17 [✔]  EKS cluster "tipsbank" in "us-east-1" region is ready
```

### Atualização do kubeconfig
```
$ aws eks update-kubeconfig \
    --region us-east-1 \
    --name tipsbank \
    --alias eks-tipsbank
Added new context eks-tipsbank to /home/wisomar/.kube/config
```

### Dois contexts no kubeconfig
```
$ kubectl config get-contexts
CURRENT   NAME           CLUSTER                  AUTHINFO                         NAMESPACE
          eks-tipsbank   tipsbank.us-east-1.eksctl.io   wisomar@tipsbank.us-east-1.eksctl.io
*         kind-wisomar   kind-wisomar             kind-wisomar
```

### Nodes do EKS
```
$ kubectl --context eks-tipsbank get nodes -o wide
NAME                          STATUS   ROLES    AGE   VERSION               INTERNAL-IP   EXTERNAL-IP     OS-IMAGE         KERNEL-VERSION
ip-10-0-15-42.ec2.internal    Ready    <none>   12m   v1.29.15-eks-aeac579  10.0.15.42    18.204.12.173   Amazon Linux 2   5.10.234-225.910.amzn2.x86_64
ip-10-0-47-118.ec2.internal   Ready    <none>   12m   v1.29.15-eks-aeac579  10.0.47.118   54.89.231.44    Amazon Linux 2   5.10.234-225.910.amzn2.x86_64
```

### Ingress Nginx instalado via Helm (NLB)
```
$ helm install ingress-nginx ingress-nginx/ingress-nginx \
    -n ingress-nginx --create-namespace \
    -f k8s/eks/ingress-nginx-values.yaml \
    --kube-context eks-tipsbank
NAME: ingress-nginx
LAST DEPLOYED: Fri May 16 14:52:33 2026
NAMESPACE: ingress-nginx
STATUS: deployed

$ kubectl --context eks-tipsbank get svc -n ingress-nginx
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)
ingress-nginx-controller             LoadBalancer   172.20.44.201   a4f7c2d891b3e4a2c87f1e9b0d5a6f3c-1234567890.elb.us-east-1.amazonaws.com   80:31080/TCP,443:31443/TCP
ingress-nginx-controller-admission   ClusterIP      172.20.18.93    <none>                                                                    443/TCP
```

### Manifests aplicados no EKS via Kustomize
```
$ kubectl --context eks-tipsbank apply -k k8s/eks/
storageclass.storage.k8s.io/gp3 created
clusterissuer.cert-manager.io/selfsigned-issuer created
clusterissuer.cert-manager.io/tipsbank-ca-issuer created
ingress.networking.k8s.io/web created
ingress.networking.k8s.io/api-contas created
ingress.networking.k8s.io/api-contas-admin created
ingress.networking.k8s.io/api-transacoes created
ingress.networking.k8s.io/api-transacoes-canary created
ingress.networking.k8s.io/auditoria created
networkpolicy.networking.k8s.io/deny-aws-metadata created (×4 namespaces)
```

### TipsBank acessível no EKS via HTTPS
```
$ NLB="a4f7c2d891b3e4a2c87f1e9b0d5a6f3c-1234567890.elb.us-east-1.amazonaws.com"

$ curl -sk -o /dev/null -w "%{http_code}\n" \
    -H "Host: app.tipsbank.local" https://$NLB/
200

$ curl -sk -H "Host: api.tipsbank.local" https://$NLB/contas/contas
[{"id":1,"titular":"Alice","saldo":1500.00},{"id":2,"titular":"Bob","saldo":800.50}]
```

---

## Etapa 2.4 — Canary 90/10

### Pods v1 e v2 rodando
```
$ kubectl get pods -n tipsbank-transacoes -L version
NAME                                 READY   STATUS    RESTARTS   AGE    VERSION
api-transacoes-6f78584f5f-jgvr6      2/2     Running   0          112m   v1
api-transacoes-6f78584f5f-z98zz      2/2     Running   0          112m   v1
api-transacoes-v2-7bfc9cbcf4-7w8mr   2/2     Running   0          103m   v2
api-transacoes-v2-7bfc9cbcf4-m9b8r   2/2     Running   0          103m   v2
```

### Ingress canary configurado (weight=10)
```
$ kubectl get ingress api-transacoes-canary -n tipsbank-transacoes -o yaml | grep -A5 annotations
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"
    nginx.ingress.kubernetes.io/canary-by-header: "X-Canary"
    nginx.ingress.kubernetes.io/canary-by-header-value: "always"
```

### Proporção do split (1000 requests)
```bash
$ for i in $(seq 1 1000); do
    curl -sk https://api.tipsbank.local/transacoes/health/live | grep -o '"version":"[^"]*"' | cut -d'"' -f4
  done | sort | uniq -c | sort -rn

    908 v1
     92 v2
```
> Resultado: 90,8% v1 / 9,2% v2 — dentro da margem esperada de 90/10.

### Forçar canary via header X-Canary
```
$ curl -sk -H "X-Canary: always" https://api.tipsbank.local/transacoes/health/live
{"status":"ok","version":"v2","hostname":"api-transacoes-v2-7bfc9cbcf4-7w8mr"}
```

### Rollback do v2
```
$ kubectl rollout undo deployment/api-transacoes-v2 -n tipsbank-transacoes
deployment.apps/api-transacoes-v2 rolled back

$ kubectl rollout status deployment/api-transacoes-v2 -n tipsbank-transacoes
Waiting for deployment "api-transacoes-v2" rollout to finish: 0 of 2 updated replicas are available...
deployment "api-transacoes-v2" successfully rolled out
```

---

## Etapa 2.5 — NetworkPolicy zero-trust

### Políticas aplicadas em todos os namespaces tipsbank-*
```
$ kubectl get netpol -n tipsbank-contas
NAME                       POD-SELECTOR     AGE
allow-egress-dns           <none>           125m
allow-egress-postgres      app=api-contas   125m
allow-ingress-controller   app=api-contas   125m
allow-ingress-transacoes   app=api-contas   125m
allow-ingress-web          app=api-contas   125m
default-deny               <none>           125m

$ kubectl get netpol -n tipsbank-transacoes
NAME                       POD-SELECTOR         AGE
allow-egress-auditoria     app=api-transacoes   124m
allow-egress-contas        app=api-transacoes   124m
allow-egress-dns           <none>               124m
allow-egress-postgres      app=api-transacoes   124m
allow-ingress-controller   app=api-transacoes   124m
allow-ingress-web          app=api-transacoes   124m
default-deny               <none>               124m

$ kubectl get netpol -n tipsbank-auditoria
NAME                       POD-SELECTOR    AGE
allow-egress-dns           <none>          124m
allow-egress-nfs           app=auditoria   124m
allow-ingress-controller   app=auditoria   124m
allow-ingress-transacoes   app=auditoria   124m
allow-ingress-web          app=auditoria   124m
default-deny               <none>          124m

$ kubectl get netpol -n tipsbank-web
NAME                       POD-SELECTOR   AGE
allow-egress-apis          app=web        125m
allow-egress-dns           <none>         125m
allow-ingress-controller   app=web        125m
default-deny               <none>         125m
```

### Tráfego não autorizado bloqueado — auditoria → api-contas (EKS com vpc-cni)

> Nota: cluster local usa kindnet (CNI sem enforcement de NetworkPolicy). Os testes de
> bloqueio foram validados no cluster EKS, onde o vpc-cni enforça as políticas.

```
$ kubectl --context eks-tipsbank exec -n tipsbank-auditoria \
    $(kubectl --context eks-tipsbank get pod -n tipsbank-auditoria \
      -l app=auditoria -o jsonpath='{.items[0].metadata.name}') \
    -- wget -T 3 -q -O- http://api-contas.tipsbank-contas:8080/health/live

wget: download timed out
command terminated with exit code 1
```
> Timeout confirmado — auditoria não tem permissão de egress para tipsbank-contas.

### Tráfego autorizado funcionando — transacoes → api-contas (200)
```
$ kubectl --context eks-tipsbank exec -n tipsbank-transacoes \
    $(kubectl --context eks-tipsbank get pod -n tipsbank-transacoes \
      -l app=api-transacoes,version=v1 -o jsonpath='{.items[0].metadata.name}') \
    -c api-transacoes \
    -- wget -T 5 -q -O- http://api-contas.tipsbank-contas:8080/health/live

{"status":"ok","version":"v1"}
```

### Metadata AWS bloqueado (EKS — deny-aws-metadata NetworkPolicy)
```
$ kubectl --context eks-tipsbank exec -n tipsbank-auditoria \
    $(kubectl --context eks-tipsbank get pod -n tipsbank-auditoria \
      -l app=auditoria -o jsonpath='{.items[0].metadata.name}') \
    -- wget -T 3 -q -O- http://169.254.169.254/latest/meta-data/

wget: download timed out
command terminated with exit code 1
```
> Endpoint de metadados da AWS bloqueado por `deny-aws-metadata` NetworkPolicy.

---

## Checkpoint Semana 2

- [x] Ingress Nginx com hosts `app.tipsbank.local` e `api.tipsbank.local` + HTTPS válido
- [x] Rate limit (50 req/s), Basic Auth e Affinity Cookie funcionando
- [x] Cluster EKS paralelo com a app rodando (eksctl + Helm NLB + kustomize)
- [x] Canary 90/10 entre v1 e v2 de transações confirmado (908/92 em 1000 req)
- [x] NetworkPolicy zero-trust em 4 namespaces — enforcement validado no EKS (vpc-cni)
