resource "aws_instance" "web1" {
  ami                    = "ami-0e86e20dae9224db8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  tags = { Name = "Web1" }
}

resource "aws_instance" "web2" {
  ami                    = "ami-0e86e20dae9224db8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  tags = { Name = "Web2" }
}

resource "aws_instance" "db1" {
  ami                    = "ami-0e86e20dae9224db8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  tags = { Name = "DB1" }
}

resource "aws_instance" "db2" {
  ami                    = "ami-0e86e20dae9224db8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private2.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  tags = { Name = "DB2" }
}