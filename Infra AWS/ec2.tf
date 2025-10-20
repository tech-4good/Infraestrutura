resource "aws_instance" "web1" {
  ami                    = "ami-0e86e20dae9224db8"
  key_name               = "vockey"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  private_ip             = "10.0.0.4"

  user_data = join("\n\n", [
        file("${path.module}/scripts/instalar_docker_ubuntu.sh"),
        file("${path.module}/scripts/instalar_nginx.sh"),
        file("${path.module}/scripts/instalar_python_ubuntu.sh"),
        "mkdir -p /home/ubuntu/backend",
        "sudo chown -R ubuntu:ubuntu /home/ubuntu/backend",
        "sudo chmod 755 /home/ubuntu/backend"
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
  private_ip             = "10.0.0.36"

  user_data = join("\n\n", [
        file("${path.module}/scripts/instalar_docker_ubuntu.sh"),
        file("${path.module}/scripts/instalar_nginx.sh"),
        "mkdir -p /home/ubuntu/backend",
        "sudo chown -R ubuntu:ubuntu /home/ubuntu/backend",
        "sudo chmod 755 /home/ubuntu/backend"
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
    })
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