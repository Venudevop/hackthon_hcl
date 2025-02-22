provider "aws" {
  region = "us-east-1" 
  secret_key=""
  access_id=""
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Main-VPC"
  }
}

# Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"  # Public subnet CIDR
  availability_zone       = "us-west-2a"    # Choose your AZ
  map_public_ip_on_launch = true  # This enables public IP assignment to instances in this subnet
  tags = {
    Name = "Public-Subnet"
  }
}

# Create a Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"  # Private subnet CIDR
  availability_zone = "us-west-2b"    # Choose your AZ
  tags = {
    Name = "Private-Subnet"
  }
}

# Create an Internet Gateway (for Public Subnet)
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Main-Internet-Gateway"
  }
}

# Create a Route Table for the Public Subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"  # Allow all traffic
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# Associate the Public Subnet with the Route Table
resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a NAT Gateway (Optional, for Private Subnet internet access)
resource "aws_eip" "nat_ip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.public_subnet.id  # NAT Gateway must be in the public subnet

  tags = {
    Name = "NAT-Gateway"
  }
}

# Create a Route Table for the Private Subnet (with NAT Gateway)
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id  # Route internet traffic through NAT Gateway
  }

  tags = {
    Name = "Private-Route-Table"
  }
}

# Associate the Private Subnet with the Route Table
resource "aws_route_table_association" "private_route_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}


terraform {
  backend "s3" {
    bucket         = "venu_hcl_hackthon"  
    key            = "path/to/your/terraform/statefile.tfstate"
    region         = "us-east-1"   # AWS region where the bucket is located
    encrypt        = true  # Encrypt the state file in S3
    dynamodb_table  = "your-dynamodb-lock-table"  
    acl            = "private"  # ACL for the S3 object (default is private)
  }
}

