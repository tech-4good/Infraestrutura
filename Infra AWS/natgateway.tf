resource "aws_eip" "nat_gateway_eip" {
    domain = "vpc"
}

resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat_gateway_eip.id
    subnet_id = aws_subnet.public1.id
}

resource "aws_route_table" "route_table_privada" {
    vpc_id = aws_vpc.vpc_techFourGood.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
    }
    tags = {
        Name = "subrede-privada-route-table"
    }
}