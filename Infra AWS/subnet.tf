resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.vpc_techFourGood.id
  cidr_block              = "10.0.0.0/28"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  tags = { Name = "Public-1" }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.vpc_techFourGood.id
  cidr_block              = "10.0.0.32/28"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "Public-2" }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.vpc_techFourGood.id
  cidr_block        = "10.0.0.16/28"
  availability_zone = "us-east-1c"
  tags = { Name = "Private-1" }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.vpc_techFourGood.id
  cidr_block        = "10.0.0.48/28"
  availability_zone = "us-east-1b"
  tags = { Name = "Private-2" }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.route_table_privada.id
}
resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.route_table_privada.id
}