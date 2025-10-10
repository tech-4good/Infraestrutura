resource "aws_eip" "web1_eip" {
  instance = aws_instance.web1.id
  tags = {
    Name = "web1-eip"
  }
}

resource "aws_eip" "web2_eip" {
  instance = aws_instance.web2.id
  tags = {
    Name = "web2-eip"
  }
}

output "web1_public_ip" {
  value = aws_eip.web1_eip.public_ip
}

output "web2_public_ip" {
  value = aws_eip.web2_eip.public_ip
}
