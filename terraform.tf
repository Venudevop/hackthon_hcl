resource "aws_vpc" "hclvpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "publicsubnet" {
  vpc_id                  = aws_vpc.hclvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_subnet" "privatesubnet" {
  vpc_id            = aws_vpc.hclvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-2a"
  tags = {
    Name = "PrivateSubnet"
  }
}

resource "aws_internet_gateway" "IG" {
  vpc_id = aws_vpc.hclvpc.id
  tags = {
    Name = "IG"
  }
}

resource "aws_nat_gateway" "NAT" {
  subnet_id     = aws_subnet.publicsubnet.id
 # allocation_id = aws_eip.nat.id # Reference to the Elastic IP (we'll define this next)

  tags = {
    Name = "NATGateway"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.hclvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IG.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.hclvpc.id

  route {
    cidr_block        = "0.0.0.0/0"
    nat_gateway_id    = aws_nat_gateway.NAT.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.privatesubnet.id
  route_table_id = aws_route_table.private.id
}
