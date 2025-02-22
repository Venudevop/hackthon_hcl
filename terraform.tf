

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
  availability_zone       = "us-east-1a"    # Choose your AZ
  map_public_ip_on_launch = true  # This enables public IP assignment to instances in this subnet
  tags = {
    Name = "Public-Subnet"
  }
}

# Create a Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"  # Private subnet CIDR
  availability_zone = "us-east-1b"    # Choose your AZ
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
#resource "aws_eip" "nat_ip" {
  #vpc = true
#}

resource "aws_nat_gateway" "nat_gateway" {
#  allocation_id = aws_eip.nat_ip.id
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
    bucket         = "venuking37512345"  
    key            = "terraform/statefile.tfstate"
    region         = "us-east-1"   # AWS region where the bucket is located
    encrypt        = true  # Encrypt the state file in S3
    dynamodb_table  = "your-dynamodb-lock-table"  
    acl            = "private"  # ACL for the S3 object (default is private)
  }
}



####################################



# Create Security Group to Allow All IPs
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Security group allowing all inbound traffic"
  vpc_id      = "vpc-id"  # Replace with your VPC ID

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all IP addresses
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Fetch Availability Zones in the region
data "aws_availability_zones" "available" {}

# Launch EC2 Instance 1 in the first Availability Zone
resource "aws_instance" "ec2_instance_1" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with your desired AMI ID
  instance_type = "t2.medium"
 # iam_instance_profile = aws_iam_role.ec2_role.name
  security_groups = [aws_security_group.ec2_sg.name]
  subnet_id      = "aws_subnet.public_subnet.id"  # Replace with your subnet ID in AZ 1
  key_name       = "var.keyname"  # Replace with your EC2 key pair name

  availability_zone = data.aws_availability_zones.available.names[0]  # AZ1
  tags = {
    Name = "EC2-Instance-1"
  }
}

# Launch EC2 Instance 2 in the second Availability Zone
resource "aws_instance" "ec2_instance_2" {
  ami           = "var.image.id"  # Replace with your desired AMI ID
  instance_type = "t2.micro"
 # iam_instance_profile = aws_iam_role.ec2_role.name
  security_groups = [aws_security_group.ec2_sg.name]
  subnet_id      = "subnet-id-2"  # Replace with your subnet ID in AZ 2
  key_name       = "your-key-name"  # Replace with your EC2 key pair name

  availability_zone = data.aws_availability_zones.available.names[1]  # AZ2
  tags = {
    Name = "EC2-Instance-2"
  }
}



#######Fargate#############

# Define ECS Cluster
resource "aws_ecs_cluster" "fargate_cluster" {
  name = "fargate-cluster"
}

# Define ECS Task Definition
resource "aws_ecs_task_definition" "fargate_task" {
  family                = "my-task-family"
 # execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn
 # task_role_arn         = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode          = "awsvpc"
  container_definitions = jsonencode([{
    name      = "my-container"
    image     = "my-ecr-repo/my-app-image:latest"
    cpu       = 256
    memory    = 512
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
  }])
}

# Define ECS Service
resource "aws_ecs_service" "fargate_service" {
  name            = "fargate-service"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.fargate_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.private_subnet.id]
    security_groups = [aws_security_group.ecs_security_group.id]
    assign_public_ip = true
  }
}
