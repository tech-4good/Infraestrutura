resource "aws_instance" "web1" {
  ami                    = "ami-0e86e20dae9224db8"
  key_name               = "vockey"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = join("\n\n", [
        file("${path.module}/scripts/instalar_docker_ubuntu.sh"),
        file("${path.module}/scripts/instalar_nginx.sh"),
        <<-EOT
        #!/bin/bash
        set -e
        
        # Configurar diretório de backend
        mkdir -p /home/ubuntu/backend
        sudo chown -R ubuntu:ubuntu /home/ubuntu/backend
        sudo chmod 755 /home/ubuntu/backend
        
        # Garantir permissões SSH corretas
        sudo -u ubuntu chmod 700 /home/ubuntu/.ssh
        sudo -u ubuntu chmod 600 /home/ubuntu/.ssh/authorized_keys
        sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh
        
        # Log de confirmação
        echo "Web1 SSH setup completed at $(date)" | sudo tee -a /var/log/user-data.log

        # Forçar instalação de dependências Python via apt (pacotes do sistema Ubuntu)
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y python3 python3-pika python3-requests

        # Validar instalação
        python3 -c "import pika, requests; print('Dependências Python OK')" 2>&1 | sudo tee -a /var/log/user-data.log

        # Garantir execução no boot (cron @reboot) usando python3 do sistema
        su - ubuntu -c '(crontab -l 2>/dev/null; echo "@reboot /usr/bin/python3 /home/ubuntu/voluntario_email_consumer.py >> /home/ubuntu/consumer.log 2>&1") | crontab -'

        echo "Consumer cron configured at $(date)" | sudo tee -a /var/log/user-data.log
        EOT
    ])

  user_data_replace_on_change = true

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./vockey.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source = "scripts/compose-nginx.yaml"
    destination = "/home/ubuntu/compose.yaml"
  }

  provisioner "file" {
    source = "scripts/nginx.conf"
    destination = "/home/ubuntu/nginx.conf"
  }

  provisioner "file" {
    source = "scripts/compose-api.yaml"
    destination = "/home/ubuntu/compose-api.yaml"
  }

  tags = { Name = "Web1" }
}



resource "aws_instance" "web2" {
  ami                    = "ami-0e86e20dae9224db8"
  key_name               = "vockey"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = join("\n\n", [
        file("${path.module}/scripts/instalar_docker_ubuntu.sh"),
        file("${path.module}/scripts/instalar_nginx.sh"),
        <<-EOT
        #!/bin/bash
        # Configurar diretório de backend
        mkdir -p /home/ubuntu/backend
        sudo chown -R ubuntu:ubuntu /home/ubuntu/backend
        sudo chmod 755 /home/ubuntu/backend
        
        # Garantir permissões SSH corretas
        sudo -u ubuntu chmod 700 /home/ubuntu/.ssh
        sudo -u ubuntu chmod 600 /home/ubuntu/.ssh/authorized_keys
        sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh
        
        # Log de confirmação
        echo "Web2 SSH setup completed at $(date)" | sudo tee -a /var/log/user-data.log
        EOT
    ])

  user_data_replace_on_change = true

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./vockey.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source = "scripts/compose-nginx.yaml"
    destination = "/home/ubuntu/compose.yaml"
  }

  provisioner "file" {
    source = "scripts/nginx.conf"
    destination = "/home/ubuntu/nginx.conf"
  }

  tags = { Name = "Web2" }
}

resource "aws_instance" "db1" {
  ami                    = "ami-0e86e20dae9224db8"
  key_name               = "vockey"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  private_ip             = "10.0.0.20"

  user_data = join("\n\n", [
    file("${path.module}/scripts/instalar_docker_ubuntu.sh"),
    file("${path.module}/scripts/instalar_python_ubuntu.sh"),
    templatefile("${path.module}/scripts/instalar_java.sh", {
      arquivo_docker_compose = base64encode(file("${path.module}/scripts/compose-api.yaml"))
    }),
    <<-EOT
    #!/bin/bash
    # Garantir que a chave SSH vockey está no authorized_keys
    # Isso permite que Web1/Web2 conectem na DB1 usando a mesma chave
    
    # Gerar a chave pública a partir da chave privada do par vockey
    # (A AWS já adiciona automaticamente ao criar a instância, mas vamos garantir)
    
    # Criar diretório .ssh se não existir
    sudo -u ubuntu mkdir -p /home/ubuntu/.ssh
    sudo -u ubuntu chmod 700 /home/ubuntu/.ssh
    
    # A AWS já adiciona a chave do par vockey automaticamente
    # Mas vamos garantir que as permissões estão corretas
    sudo -u ubuntu chmod 600 /home/ubuntu/.ssh/authorized_keys
    sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    
    # Log para debug
    echo "SSH setup completed at $(date)" | sudo tee -a /var/log/user-data.log
    ls -la /home/ubuntu/.ssh/ | sudo tee -a /var/log/user-data.log
    EOT
  ])

  user_data_replace_on_change = true

  tags                   = { Name = "DB1" }
}

resource "aws_instance" "db2" {
  ami                    = "ami-0e86e20dae9224db8"
  key_name               = "vockey"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private2.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  private_ip             = "10.0.0.52"
  tags                   = { Name = "DB2" }
}

# ----------------------------------------------------------------------------
# Deploy do consumer de e-mail APÓS o EIP estar associado na Web1
# Evita usar self.public_ip durante a criação da instância (que ainda não tem EIP)
# ----------------------------------------------------------------------------
resource "null_resource" "deploy_consumer_web1" {
  depends_on = [
    aws_eip.web1_eip,
    aws_instance.web1,
    aws_instance.db1
  ]

  # Garante reexecução quando o template mudar ou o IP do EIP mudar
  triggers = {
    template_sha = filesha256("${path.module}/scripts/voluntario_email_consumer.py")
    web1_ip      = aws_eip.web1_eip.public_ip
    db1_ip       = aws_instance.db1.private_ip
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./vockey.pem")
    host        = aws_eip.web1_eip.public_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/voluntario_email_consumer.py", {
      frontend_url = "http://${aws_eip.web1_eip.public_ip}/redefinir-senha"
      rabbitmq_host = aws_instance.db1.private_ip
    })
    destination = "/home/ubuntu/voluntario_email_consumer.py"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chown ubuntu:ubuntu /home/ubuntu/voluntario_email_consumer.py",
      "sudo chmod 644 /home/ubuntu/voluntario_email_consumer.py",
      # Reiniciar o consumer para usar o novo arquivo imediatamente
      "pkill -f voluntario_email_consumer.py || true",
      "nohup /usr/bin/python3 /home/ubuntu/voluntario_email_consumer.py >> /home/ubuntu/consumer.log 2>&1 &"
    ]
  }
}