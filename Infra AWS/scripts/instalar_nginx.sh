#!/bin/bash

# criando o diretório de html e estrutura nginx
# ATENÇÃO! se o usuário da EC2 for ubuntu, trocar ec2-user por ubuntu

mkdir -p /home/ubuntu/frontend/nginx/templates
mkdir -p /home/ubuntu/frontend/nginx/conf.d
chown -R ubuntu:ubuntu /home/ubuntu/frontend
echo "<h1>Uh papai! NGINX via Docker Compose!</h1>" > /home/ubuntu/frontend/index.html
echo "Diretórios do nginx criados com sucesso."

# Aguardar o Docker estar totalmente pronto
sleep 10

sudo docker compose -f /home/ubuntu/compose.yaml up -d
echo "NGINX iniciado com sucesso."

# Aguardar o Nginx estar respondendo
sleep 5

# Criar endpoint /health se ainda não existir
if [ ! -f "/home/ubuntu/frontend/nginx/conf.d/default.conf" ]; then
  echo 'server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}' > /home/ubuntu/frontend/nginx/conf.d/default.conf
  sudo docker compose -f /home/ubuntu/compose.yaml restart
fi

echo "NGINX health check configurado e pronto."