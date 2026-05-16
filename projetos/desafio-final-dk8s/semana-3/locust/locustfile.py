"""
Locust - stress test do TipsBank.
Simula usuarios criando contas e fazendo transferencias.

Execucao local:
    locust -f locustfile.py --host http://localhost:8082

Execucao em Kubernetes (Deployment no cluster):
    LOCUST_HOST=http://api-transacoes.tipsbank-transacoes.svc.cluster.local:8080
    CONTAS_URL=http://api-contas.tipsbank-contas.svc.cluster.local:8080
"""
import os
import random
import uuid
from decimal import Decimal
from locust import HttpUser, task, between, events
import httpx

CONTAS_CRIADAS: list[str] = []

CONTAS_URL = os.getenv(
    "CONTAS_URL",
    "http://api-contas.tipsbank-contas.svc.cluster.local:8080",
)


class UsuarioBanco(HttpUser):
    wait_time = between(0.5, 2)

    def on_start(self):
        """Cria uma conta por usuario para termos saldo disponivel."""
        documento = "".join(random.choices("0123456789", k=11))
        payload = {
            "titular": f"Aluno {uuid.uuid4().hex[:6]}",
            "documento": documento,
            "senha": "giropops123",
            "saldo_inicial": "10000.00",
        }
        try:
            r = httpx.post(f"{CONTAS_URL}/contas", json=payload, timeout=10)
            if r.status_code == 201:
                CONTAS_CRIADAS.append(r.json()["id"])
        except Exception as e:
            print(f"Erro ao criar conta: {e}")

    @task(3)
    def transferir(self):
        if len(CONTAS_CRIADAS) < 2:
            return
        origem, destino = random.sample(CONTAS_CRIADAS, 2)
        valor = round(random.uniform(1, 50), 2)
        self.client.post(
            "/transferencias",
            json={"origem_id": origem, "destino_id": destino, "valor": str(valor)},
            name="/transferencias",
        )

    @task(1)
    def consultar_extrato(self):
        if not CONTAS_CRIADAS:
            return
        conta = random.choice(CONTAS_CRIADAS)
        self.client.get(f"/extrato/{conta}", name="/extrato/:id")


@events.test_stop.add_listener
def resumo(environment, **_):
    print(f"\nContas criadas durante o teste: {len(CONTAS_CRIADAS)}")
