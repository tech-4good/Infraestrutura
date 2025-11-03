# Guia de Teste do RabbitMQ após o Deploy

Este guia descreve um passo a passo objetivo para validar o RabbitMQ, a API e o consumer após o deploy do front-end e back-end na AWS.

## Pré-requisitos
- Terraform aplicado (EC2 Web1, Web2, DB1 criadas) e security groups já existentes.
- Na DB1, o arquivo `compose-api.yaml` está em uso, com serviços `rabbitmq`, `mysql` e `api` rodando.
- O arquivo `voluntario_email_consumer.py` foi copiado para a Web1 em `/home/ubuntu/` e as dependências Python foram instaladas pelo user-data.

## 1) Verificar containers na DB1 (RabbitMQ/MySQL/API)

Conecte-se à DB1. Como ela é privada, use a Web1 como “jump host”. No Windows PowerShell:

```powershell
# Opção A (jump direto):
ssh -i .\vockey.pem -J ubuntu@<WEB1_PUBLIC_IP> ubuntu@10.0.0.20

# Opção B (dois passos):
ssh -i .\vockey.pem ubuntu@<WEB1_PUBLIC_IP>
ssh ubuntu@10.0.0.20
```

Na DB1, verifique o estado dos containers e os logs do RabbitMQ:

```bash
docker compose -f /home/ubuntu/compose-api.yaml ps
docker compose -f /home/ubuntu/compose-api.yaml logs -f rabbitmq
```

Você deve ver `rabbitmq`, `mysql` e `api` em estado “Up”.

## 2) Abrir o console do RabbitMQ (15672) via túnel SSH

Crie um túnel local da sua máquina para a DB1 através da Web1 (mantenha a sessão aberta):

```powershell
ssh -i .\vockey.pem -L 15672:10.0.0.20:15672 ubuntu@<WEB1_PUBLIC_IP>
```

No navegador, acesse: http://localhost:15672  
Credenciais padrão do compose: `admin` / `admin123`.

No menu Queues, confirme a existência das filas:
- `tech4good.voluntario.queue`
- `tech4good.filaespera.queue`

## 3) Subir o consumer na Web1

Abra uma sessão na Web1:

```powershell
ssh -i .\vockey.pem ubuntu@<WEB1_PUBLIC_IP>
```

Execute o consumer:

```bash
python3 /home/ubuntu/voluntario_email_consumer.py
```

Saída esperada:
- “Conectado ao RabbitMQ em 10.0.0.20:5672”
- “Aguardando mensagens da fila: tech4good.voluntario.queue”

Para rodar em background durante o teste:

```bash
nohup python3 /home/ubuntu/voluntario_email_consumer.py > consumer.log 2>&1 &
tail -f consumer.log
```

## 4) Publicar uma mensagem (end-to-end ou manual)

- Caminho end-to-end (recomendado):
  1. No front-end, utilize o fluxo de “Recuperar senha/Esqueci minha senha”.
  2. A API publicará o evento na fila `tech4good.voluntario.queue`.
  3. Acompanhe no console do RabbitMQ a variação da fila (mensagens entrando e sendo consumidas).
  4. Veja os logs do consumer confirmando o processamento.

- Publicação manual (para isolar backend):
  1. Console do RabbitMQ → Queues → `tech4good.voluntario.queue` → Publish message.
  2. Envie um JSON de teste:

```json
{
  "voluntarioId": 123,
  "voluntarioNome": "Fulano Teste",
  "voluntarioEmail": "seu.email@exemplo.com",
  "tokenRedefinicao": "abc123",
  "dataEvento": "2025-11-03T12:34:56Z"
}
```

Mensagens devem ser consumidas e sumir da fila; o consumer imprimirá logs.

## 5) Checks rápidos

- Logs da API (na DB1):

```bash
docker compose -f /home/ubuntu/compose-api.yaml logs -f api
```

- Estatísticas de fila: use o console do RabbitMQ e observe “Ready/Unacked”.

- Conectividade Web1 → DB1 (porta 5672):

```bash
# (opcional) instalar netcat:
sudo apt update && sudo apt install -y netcat
nc -zv 10.0.0.20 5672
```

## 6) Problemas comuns e soluções mínimas

- Consumer não conecta:
  - Verifique se o RabbitMQ está “Up” na DB1.
  - Confira as credenciais: `admin` / `admin123`.
  - Teste a porta 5672 da DB1 a partir da Web1 (ver seção “Checks rápidos”).

- API não publica mensagens:
  - Veja logs da API em busca de erros de conexão com RabbitMQ.
  - Confirme que a API e o RabbitMQ estão na mesma rede do Docker (já configurado no compose).
  - Se necessário, publique manualmente para isolar o problema do backend.

- Console 15672 não abre no navegador:
  - Garanta que o túnel SSH está ativo e use `http://localhost:15672`.

## 7) (Opcional) Executar o consumer automaticamente

Crie um serviço systemd na Web1 para iniciar o consumer após boot:

```ini
[Unit]
Description=Tech4Good - Voluntario Email Consumer
After=network-online.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/python3 /home/ubuntu/voluntario_email_consumer.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

Comandos (na Web1):

```bash
echo "<conteudo acima>" | sudo tee /etc/systemd/system/voluntario-email-consumer.service
sudo systemctl daemon-reload
sudo systemctl enable --now voluntario-email-consumer
sudo systemctl status voluntario-email-consumer
```

---

Pronto. Com estes passos você valida que:
- RabbitMQ está rodando na DB1 e acessível.
- A API publica nas filas corretamente.
- O consumer Python consome e processa as mensagens.
