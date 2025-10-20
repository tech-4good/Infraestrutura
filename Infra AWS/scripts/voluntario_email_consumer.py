"""
Consumer Python para envio de emails de redefinição de senha
Recebe mensagens da fila RabbitMQ e envia emails via API Maileroo

CONFIGURAÇÃO:
Edite as variáveis na seção CONFIG abaixo com suas credenciais
"""

import pika
import json
import sys
import requests
from datetime import datetime
from typing import Dict, Any


# ============================================================================
# CONFIGURAÇÕES - EDITE AQUI COM SUAS CREDENCIAIS
# ============================================================================

CONFIG = {
    # Configurações do RabbitMQ
    'RABBITMQ_HOST': '${rabbitmq_host}',
    'RABBITMQ_PORT': 5672,
    'RABBITMQ_USER': 'admin',
    'RABBITMQ_PASSWORD': 'admin123',
    'RABBITMQ_QUEUE': 'tech4good.voluntario.queue',
    
    # Configurações do Maileroo
    'MAILEROO_API_KEY': '3d5673d05e3a9419904f43a83e46c4286970a2f7d952346092ca15717a8c4960',
    'MAILEROO_API_URL': 'https://smtp.maileroo.com/api/v2/emails',
    'MAILEROO_FROM_EMAIL': 'tech4good@149994e461e69d37.maileroo.org',
    
    # URL do Frontend (para link de redefinição de senha) - CONFIGURADA DINAMICAMENTE
    'FRONTEND_URL': '${frontend_url}',
}

# ============================================================================


class VoluntarioEmailConsumer:
    def __init__(self, 
                 rabbitmq_host: str = None, 
                 rabbitmq_port: int = None,
                 rabbitmq_user: str = None,
                 rabbitmq_password: str = None,
                 queue_name: str = None,
                 maileroo_api_key: str = None,
                 maileroo_api_url: str = None,
                 maileroo_from_email: str = None,
                 frontend_url: str = None):
        """
        Inicializa o consumer de emails do voluntário
        
        Args:
            Todos os parâmetros são opcionais. Se não fornecidos, usa as configurações do dicionário CONFIG
        """
        self.rabbitmq_host = rabbitmq_host or CONFIG['RABBITMQ_HOST']
        self.rabbitmq_port = rabbitmq_port or CONFIG['RABBITMQ_PORT']
        self.rabbitmq_user = rabbitmq_user or CONFIG['RABBITMQ_USER']
        self.rabbitmq_password = rabbitmq_password or CONFIG['RABBITMQ_PASSWORD']
        self.queue_name = queue_name or CONFIG['RABBITMQ_QUEUE']
        self.maileroo_api_key = maileroo_api_key or CONFIG['MAILEROO_API_KEY']
        self.maileroo_api_url = maileroo_api_url or CONFIG['MAILEROO_API_URL']
        self.maileroo_from_email = maileroo_from_email or CONFIG['MAILEROO_FROM_EMAIL']
        self.frontend_url = frontend_url or CONFIG['FRONTEND_URL']
        self.connection = None
        self.channel = None
        
        # Validação da API Key
        if (not self.maileroo_api_key or 
            self.maileroo_api_key == 'YOUR_MAILEROO_API_KEY_HERE' or
            len(self.maileroo_api_key) < 10):
            raise ValueError(
                "\nERRO: MAILEROO_API_KEY não configurada!\n"
                f"Valor atual: '{self.maileroo_api_key}'\n"
                "Edite o arquivo voluntario_email_consumer.py e altere a variável CONFIG['MAILEROO_API_KEY']"
            )

        
    def connect(self):
        """Estabelece conexão com o RabbitMQ"""
        try:
            credentials = pika.PlainCredentials(self.rabbitmq_user, self.rabbitmq_password)
            parameters = pika.ConnectionParameters(
                host=self.rabbitmq_host,
                port=self.rabbitmq_port,
                credentials=credentials
            )
            
            self.connection = pika.BlockingConnection(parameters)
            self.channel = self.connection.channel()
            
            # Garante que a fila existe
            self.channel.queue_declare(queue=self.queue_name, durable=True)
            
            print(f"[OK] Conectado ao RabbitMQ em {self.rabbitmq_host}:{self.rabbitmq_port}")
            print(f"[INFO] Aguardando mensagens da fila: {self.queue_name}")
            print("[INFO] Para sair, pressione CTRL+C")
            print("-" * 70)
            
        except pika.exceptions.AMQPConnectionError as e:
            print(f"[ERRO] Erro de conexão com RabbitMQ: {e}")
            print("Verifique se o RabbitMQ está rodando e as credenciais estão corretas")
            sys.exit(1)
        except Exception as e:
            print(f"[ERRO] Erro inesperado ao conectar: {e}")
            sys.exit(1)

    def send_email_maileroo(self, to_email: str, subject: str, html_content: str, text_content: str = None, to_name: str | None = None) -> bool:
        """
        Envia email usando a API do Maileroo
        
        Args:
            to_email: Email do destinatário
            subject: Assunto do email
            html_content: Conteúdo HTML do email
            text_content: Conteúdo texto plano (opcional)
            
        Returns:
            bool: True se enviado com sucesso, False caso contrário
        """
        try:
            headers = {
                'X-API-Key': self.maileroo_api_key,
                'Content-Type': 'application/json'
            }
            
            # Monta destinatários no formato aceito pelo Maileroo API
            to_obj = {'address': to_email}
            if to_name:
                to_obj['name'] = to_name

            payload = {
                'to': [to_obj],
                'from': {
                    'address': self.maileroo_from_email,
                    'name': 'Tech4Good'
                },
                'subject': subject,
                'html': html_content
            }
            
            if text_content:
                payload['text'] = text_content
            
            response = requests.post(
                self.maileroo_api_url,
                headers=headers,
                json=payload,
                timeout=10
            )
            
            if response.status_code == 200 or response.status_code == 201:
                print(f"[OK] Email enviado com sucesso para {to_email}")
                return True
            else:
                print(f"[AVISO] Erro ao enviar email. Status: {response.status_code}")
                print(f"Resposta: {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            print(f"[ERRO] Erro na requisição para Maileroo: {e}")
            return False
        except Exception as e:
            print(f"[ERRO] Erro ao enviar email: {e}")
            return False

    def generate_reset_password_email(self, nome: str, token: str) -> tuple:
        """
        Gera o conteúdo HTML e texto do email de redefinição de senha
        
        Args:
            nome: Nome do voluntário
            token: Token de redefinição
            
        Returns:
            tuple: (html_content, text_content)
        """
        # URL de redefinição (ajuste conforme sua aplicação frontend)
        reset_url = f"{self.frontend_url}?token={token}"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; }}
                .content {{ padding: 20px; background-color: #f9f9f9; }}
                .button {{ 
                    display: inline-block; 
                    padding: 12px 24px; 
                    background-color: #4CAF50; 
                    color: white; 
                    text-decoration: none; 
                    border-radius: 4px; 
                    margin: 20px 0;
                }}
                .footer {{ text-align: center; padding: 20px; font-size: 12px; color: #666; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Tech4Good - Redefinição de Senha</h1>
                </div>
                <div class="content">
                    <p>Olá <strong>{nome}</strong>,</p>
                    <p>Você solicitou a redefinição de senha da sua conta no Tech4Good.</p>
                    <p>Para redefinir sua senha, clique no botão abaixo:</p>
                    <p style="text-align: center;">
                        <a href="{reset_url}" class="button">Redefinir Senha</a>
                    </p>
                    <p>Ou copie e cole o seguinte link no seu navegador:</p>
                    <p style="word-break: break-all; background-color: #e9e9e9; padding: 10px; border-radius: 4px;">
                        {reset_url}
                    </p>
                    <p><strong>Atenção:</strong> Este link expira em 24 horas.</p>
                    <p>Se você não solicitou esta redefinição, ignore este email.</p>
                </div>
                <div class="footer">
                    <p>Tech4Good - Tecnologia para o Bem Social</p>
                    <p>Este é um email automático, por favor não responda.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        text_content = f"""
        Tech4Good - Redefinição de Senha
        
        Olá {nome},
        
        Você solicitou a redefinição de senha da sua conta no Tech4Good.
        
        Para redefinir sua senha, acesse o seguinte link:
        {reset_url}
        
        Atenção: Este link expira em 24 horas.
        
        Se você não solicitou esta redefinição, ignore este email.
        
        Tech4Good - Tecnologia para o Bem Social
        """
        
        return html_content, text_content

    def process_message(self, ch, method, properties, body):
        """
        Processa uma mensagem recebida da fila
        
        Args:
            ch: Canal do RabbitMQ
            method: Método de entrega da mensagem
            properties: Propriedades da mensagem
            body: Corpo da mensagem (JSON)
        """
        try:
            # Decodifica o JSON da mensagem
            message_str = body.decode('utf-8')
            message_data = json.loads(message_str)
            
            # Extrai informações da mensagem
            voluntario_id = message_data.get('voluntarioId')
            voluntario_nome = message_data.get('voluntarioNome')
            voluntario_email = message_data.get('voluntarioEmail')
            token_redefinicao = message_data.get('tokenRedefinicao')
            data_evento = message_data.get('dataEvento')
            
            # Formata a saída no terminal
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            print(f"\n[MENSAGEM] NOVA MENSAGEM RECEBIDA - {timestamp}")
            print("=" * 70)
            print(f"Voluntario: {voluntario_nome} (ID: {voluntario_id})")
            print(f"Email: {voluntario_email}")
            print(f"Token: {token_redefinicao[:20]}...")
            print(f"Data do Evento: {data_evento}")
            print("-" * 70)
            
            # Gera o conteúdo do email
            html_content, text_content = self.generate_reset_password_email(
                voluntario_nome, 
                token_redefinicao
            )
            
            # Envia o email
            print(f"[INFO] Enviando email para {voluntario_email}...")
            success = self.send_email_maileroo(
                to_email=voluntario_email,
                subject="Tech4Good - Redefinição de Senha",
                html_content=html_content,
                text_content=text_content,
                to_name=voluntario_nome
            )
            
            if success:
                print("=" * 70)
                # Acknowledge da mensagem (confirma que foi processada)
                ch.basic_ack(delivery_tag=method.delivery_tag)
            else:
                print("[AVISO] Email não enviado. Mensagem será reprocessada.")
                print("=" * 70)
                # Recoloca a mensagem na fila para tentar novamente
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
            
        except json.JSONDecodeError as e:
            print(f"[ERRO] Erro ao decodificar JSON: {e}")
            print(f"Mensagem raw: {body}")
            # Rejeita a mensagem malformada
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            
        except Exception as e:
            print(f"[ERRO] Erro ao processar mensagem: {e}")
            print(f"Mensagem raw: {body}")
            # Recoloca a mensagem na fila para tentar novamente
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

    def start_consuming(self):
        """Inicia o consumo de mensagens"""
        try:
            # Configura QoS para processar uma mensagem por vez
            self.channel.basic_qos(prefetch_count=1)
            
            # Configura o consumer
            self.channel.basic_consume(
                queue=self.queue_name,
                on_message_callback=self.process_message
            )
            
            # Inicia o consumo
            self.channel.start_consuming()
            
        except KeyboardInterrupt:
            print("\n[INFO] Parando o consumer...")
            self.stop_consuming()
            
        except Exception as e:
            print(f"[ERRO] Erro durante o consumo: {e}")
            self.stop_consuming()

    def stop_consuming(self):
        """Para o consumo e fecha a conexão"""
        try:
            if self.channel:
                self.channel.stop_consuming()
                self.channel.close()
            if self.connection:
                self.connection.close()
            print("[OK] Consumer parado com sucesso")
        except Exception as e:
            print(f"[ERRO] Erro ao parar consumer: {e}")

    def print_connection_info(self):
        """Imprime informações de conexão"""
        print("\nINFORMACAO DE CONEXAO")
        print("-" * 40)
        print(f"Host RabbitMQ: {self.rabbitmq_host}")
        print(f"Porta: {self.rabbitmq_port}")
        print(f"Usuario: {self.rabbitmq_user}")
        print(f"Fila: {self.queue_name}")
        print(f"API Maileroo: Configurada")
        print(f"Email Remetente: {self.maileroo_from_email}")
        print(f"URL Frontend: {self.frontend_url}")
        print("-" * 40)


def main():
    """Função principal"""
    print("=" * 70)
    print("Tech4Good - Consumer de Email para Redefinicao de Senha")
    print("=" * 70)
    
    # Cria o consumer usando as configurações do dicionário CONFIG
    consumer = VoluntarioEmailConsumer()
    
    consumer.print_connection_info()
    consumer.connect()
    consumer.start_consuming()


if __name__ == '__main__':
    main()
