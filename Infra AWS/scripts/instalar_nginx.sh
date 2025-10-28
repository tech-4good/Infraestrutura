#!/bin/bash

# criando o diretório de html e estrutura nginx
# ATENÇÃO! se o usuário da EC2 for ubuntu, trocar ec2-user por ubuntu

mkdir -p /home/ubuntu/frontend/nginx/templates
mkdir -p /home/ubuntu/frontend/nginx/conf.d
chown -R ubuntu:ubuntu /home/ubuntu/frontend
echo "<h1>Uh papai! NGINX via Docker Compose!</h1>" > /home/ubuntu/frontend/index.html
echo "Diretórios do nginx criados com sucesso."

sudo docker compose -f /home/ubuntu/compose.yaml up -d
echo "NGINX iniciado com sucesso."