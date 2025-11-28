#!/bin/bash

################################################################################
# Script de Backup Automático do MySQL no Docker
# Função: Fazer backup do BD, enviar para S3 e notificar via email
################################################################################

set -e

# ============================================================================
# CONFIGURAÇÕES
# ============================================================================

# Data no formato ISO (aaaa-mm-dd)
DATA=$(date +"%Y-%m-%d")
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Nomes de container e banco (ajuste conforme sua configuração)
CONTAINER_MYSQL="mysql"  # Nome do container MySQL no docker-compose
BANCO_DADOS="tech4good"  # Nome do banco de dados
USUARIO_MYSQL="root"
SENHA_MYSQL="${DB_PASSWORD:-root}"  # Variável de ambiente, ou padrão 'root'

# Caminhos locais
DIR_BACKUP="/tmp/backups"
ARQUIVO_BACKUP="${DIR_BACKUP}/backup_${BANCO_DADOS}_${DATA}.sql"
ARQUIVO_LOG="${DIR_BACKUP}/backup_${DATA}.log"

# Bucket S3
BUCKET_S3="t4g-curated"  # Será substituído pelo nome real
AWS_REGION="us-east-1"

# Email
EMAIL_DESTINO="lucas.amatos@sptech.school"  # Ajuste o email do admin
ASSUNTO_SUCESSO="✓ Backup MySQL realizado com sucesso - ${DATA}"
ASSUNTO_ERRO="✗ Erro no backup MySQL - ${DATA}"

# ============================================================================
# FUNÇÕES
# ============================================================================

log_mensagem() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$ARQUIVO_LOG"
}

enviar_email() {
    local assunto="$1"
    local mensagem="$2"
    local status="$3"

    # Usando mailutils (apt-get install mailutils)
    echo "$mensagem" | mail -s "$assunto" "$EMAIL_DESTINO"
    
    log_mensagem "Email enviado: $assunto"
}

# ============================================================================
# VERIFICAÇÕES INICIAIS
# ============================================================================

log_mensagem "========== INICIANDO BACKUP =========="

# Criar diretório de backup
mkdir -p "$DIR_BACKUP"

# Verificar se Docker está rodando
if ! command -v docker &> /dev/null; then
    log_mensagem "❌ ERRO: Docker não está instalado"
    enviar_email "$ASSUNTO_ERRO" "Docker não encontrado no sistema" "erro"
    exit 1
fi

# Verificar se container MySQL está rodando
if ! docker ps | grep -q "$CONTAINER_MYSQL"; then
    log_mensagem "❌ ERRO: Container MySQL ($CONTAINER_MYSQL) não está rodando"
    enviar_email "$ASSUNTO_ERRO" "Container MySQL não está em execução" "erro"
    exit 1
fi

log_mensagem "✓ Docker e MySQL container verificados"

# ============================================================================
# FAZER BACKUP DO BANCO DE DADOS
# ============================================================================

log_mensagem "Iniciando dump do banco de dados: $BANCO_DADOS"

if docker exec "$CONTAINER_MYSQL" mysqldump \
    -u "$USUARIO_MYSQL" \
    -p"$SENHA_MYSQL" \
    --all-databases \
    --single-transaction \
    --quick \
    --lock-tables=false > "$ARQUIVO_BACKUP" 2>>"$ARQUIVO_LOG"; then
    
    TAMANHO_BACKUP=$(du -h "$ARQUIVO_BACKUP" | cut -f1)
    log_mensagem "✓ Backup criado com sucesso: $ARQUIVO_BACKUP (Tamanho: $TAMANHO_BACKUP)"
else
    log_mensagem "❌ ERRO ao criar backup do banco de dados"
    enviar_email "$ASSUNTO_ERRO" "Falha ao executar mysqldump. Verifique credenciais e container." "erro"
    exit 1
fi

# ============================================================================
# ENVIAR PARA S3
# ============================================================================

log_mensagem "Enviando arquivo para S3..."

# Obter o nome real do bucket (substitui o padrão)
BUCKET_REAL=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'analise-dados-raw')].Name" --output text 2>>"$ARQUIVO_LOG")

if [ -z "$BUCKET_REAL" ]; then
    log_mensagem "❌ ERRO: Não foi encontrado bucket S3 com padrão 'analise-dados-raw'"
    enviar_email "$ASSUNTO_ERRO" "Bucket S3 não encontrado. Verifique AWS CLI e credenciais." "erro"
    exit 1
fi

# Enviar arquivo para S3
CHAVE_S3="backups/mysql/${ARQUIVO_BACKUP##*/}"

if aws s3 cp "$ARQUIVO_BACKUP" "s3://${BUCKET_REAL}/${CHAVE_S3}" \
    --region "$AWS_REGION" 2>>"$ARQUIVO_LOG"; then
    
    log_mensagem "✓ Arquivo enviado para S3: s3://${BUCKET_REAL}/${CHAVE_S3}"
else
    log_mensagem "❌ ERRO ao enviar arquivo para S3"
    enviar_email "$ASSUNTO_ERRO" "Falha ao fazer upload para S3. Verifique credenciais AWS." "erro"
    exit 1
fi

# ============================================================================
# LIMPEZA LOCAL (opcional - manter últimos 7 dias)
# ============================================================================

log_mensagem "Limpando backups antigos (mantendo 7 dias)..."
find "$DIR_BACKUP" -name "backup_*.sql" -mtime +7 -delete 2>>"$ARQUIVO_LOG"

log_mensagem "Limpeza concluída"

# ============================================================================
# ENVIAR EMAIL DE SUCESSO
# ============================================================================

CORPO_EMAIL=$(cat <<EOF
Backup do banco de dados MySQL foi realizado com sucesso!

📊 Detalhes:
- Data: $DATA
- Banco: $BANCO_DADOS
- Tamanho: $TAMANHO_BACKUP
- Arquivo local: $ARQUIVO_BACKUP
- Localização S3: s3://${BUCKET_REAL}/${CHAVE_S3}

O arquivo será automaticamente sincronizado com S3 a cada dia.

==== Log Completo ====
$(cat "$ARQUIVO_LOG")
EOF
)

enviar_email "$ASSUNTO_SUCESSO" "$CORPO_EMAIL" "sucesso"

log_mensagem "========== BACKUP FINALIZADO COM SUCESSO =========="

exit 0
