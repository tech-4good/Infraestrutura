resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/26"
  tags = { Name = "VPC-CostExplorer" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "IGW-CostExplorer" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "RT-Public" }
}