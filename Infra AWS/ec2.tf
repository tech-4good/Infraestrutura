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
        file("${path.module}/scripts/instalar_python_ubuntu.sh"),
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
        echo "Web1 SSH setup completed at $(date)" | sudo tee -a /var/log/user-data.log

        # Python + venv para o consumer
        apt-get update -y
        apt-get install -y python3 python3-pip python3-venv

        # cria venv e instala dependências no usuário ubuntu
        su - ubuntu -c 'python3 -m venv /home/ubuntu/venvs/consumer'
        su - ubuntu -c '/home/ubuntu/venvs/consumer/bin/pip install --upgrade pip pika requests'

        # garante execução no boot (cron @reboot) usando o Python do venv
        su - ubuntu -c '(crontab -l 2>/dev/null; echo "@reboot /home/ubuntu/venvs/consumer/bin/python /home/ubuntu/voluntario_email_consumer.py >> /home/ubuntu/consumer.log 2>&1") | crontab -'

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

  provisioner "file" {
    content = templatefile("${path.module}/scripts/voluntario_email_consumer.py", {
      frontend_url = "http://${self.public_ip}:${var.frontend_port}/redefinir-senha"
      rabbitmq_host = aws_instance.db1.private_ip
    })
    destination = "/home/ubuntu/voluntario_email_consumer.py"
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