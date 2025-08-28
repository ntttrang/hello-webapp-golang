terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}



# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "hello-webapp-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "hello-webapp-public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "hello-webapp-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "hello-webapp-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Key Pair (reference existing key pair instead of creating new one)
data "aws_key_pair" "deployer" {
  key_name = var.key_name
  include_public_key = true
}

# Security Group
resource "aws_security_group" "web" {
  name_prefix = "hello-webapp-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Web app access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hello-webapp-sg"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-0c7217cdde317cfec"  # Amazon Linux 2 AMI (us-east-1)
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public.id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # Install Ansible
              yum install -y python3-pip
              pip3 install ansible

              # Create ansible user
              useradd ansible
              mkdir -p /home/ansible/.ssh
              chown ansible:ansible /home/ansible/.ssh
              chmod 700 /home/ansible/.ssh
              EOF

  tags = {
    Name = "hello-webapp-server"
  }
}

# Outputs
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.web.id
}
