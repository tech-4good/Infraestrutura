#!/bin/bash
# Script para instalar Python 3, pip e bibliotecas necessárias no Ubuntu

set -e

echo "Iniciando a instalação do Python 3 e dependências no Ubuntu Linux..."

# Atualizando a lista de pacotes
sudo apt update
echo "Lista de pacotes atualizada com sucesso."

# Instalando Python 3, pip e venv
sudo apt install -y python3 python3-pip python3-venv
echo "Python 3, pip e venv instalados com sucesso."

# Atualizando o pip
python3 -m pip install --upgrade pip
echo "pip atualizado com sucesso."

# Instalando bibliotecas Python necessárias
python3 -m pip install --no-cache-dir pika
echo "Biblioteca 'pika' instalada com sucesso."

# Verificação das importações solicitadas
python3 - <<'PYCHK'
import sys
import json
from datetime import datetime
from typing import Dict, Any
import pika

print("Verificação de importações concluída com sucesso.")
PYCHK

echo "Instalação concluída: Python e bibliotecas necessárias estão prontos."


