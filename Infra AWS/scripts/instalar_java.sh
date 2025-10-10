#!/bin/bash

# criando o diretório de html
# ATENÇÃO! se o usuário da EC2 for ubuntu, trocar ec2-user por ubuntu

sudo mkdir /home/ubuntu/backend
sudo mkdir /usr/share/api
sudo chown ubuntu:ubuntu /usr/share/api
echo "Diretório /usr/share/api criado com sucesso."

# Decodifica e salva o YAML
echo "${arquivo_docker_compose}" | base64 -d > /home/ubuntu/compose.yaml

sudo docker compose -f /home/ubuntu/compose.yaml up -d
echo "API iniciada com sucesso."