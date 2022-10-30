terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  backend "s3" {
    profile = "gw-personal"
    bucket  = "gwatts-terraform-state"
    region  = "eu-west-2"
    key     = "cyberhive/terraform.tfstate"
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-2"
  default_tags {
    tags = {
      Owner = "Graham Watts"
      Environment = "Dev"
    }
  }
}

# Create a new AWS Account in the OU Demo (OU ID: ou-xyub-6uzxm5pq) 
resource "aws_organizations_account" "cyberhive" {
  name = "CyberHive"
  email = "mail@grahamwatts.com"
  iam_user_access_to_billing = "DENY"
  role_name = "OrganizationAccountAccessRole"
  parent_id = "ou-xyub-drl94pbz"
  close_on_deletion = true
  tags = {
    Terraform = "true"
    Project = "CyberHive"
    Requestor = "Sarah Blundell"
  }
}

# Create an IAM Alias for the new account
resource "aws_iam_account_alias" "cyberhive" {
  account_alias = "cyberhive"
}

# Create a new VPC in the new AWS Account
resource "aws_vpc" "cyberhive" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "CyberHive-VPC"
    Terraform = "true"
    Project = "CyberHive"
    Requestor = "Sarah Blundell"
  }
}

# Create a new Internet Gateway for the new VPC
resource "aws_internet_gateway" "cyberhive" {
  vpc_id = aws_vpc.cyberhive.id
  tags = {
    Name = "CyberHive-IGW"
    Terraform = "true"
    Project = "CyberHive"
    Requestor = "Sarah Blundell"
  }
}

# Create 3 public subnets spread across 3 availability zones
resource "aws_subnet" "cyberhive-public-1" {
  vpc_id = aws_vpc.cyberhive.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "CyberHive-Public-1"
    Terraform = "true"
    Project = "CyberHive"
    Requestor = "Sarah Blundell"
  }
}

resource "aws_subnet" "cyberhive-public-2" {
  vpc_id = aws_vpc.cyberhive.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "CyberHive-Public-2"
    Terraform = "true"
    Project = "CyberHive"
    Requestor = "Sarah Blundell"
  }
}

resource "aws_subnet" "cyberhive-public-3" {
  vpc_id = aws_vpc.cyberhive.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "eu-west-2c"
  map_public_ip_on_launch = true
  tags = {
    Name = "CyberHive-Public-3"
    Terraform = "true"
    Project = "CyberHive"
    Requestor = "Sarah Blundell"
  }
}

# Create a route table for the public subnets
resource "aws_route_table" "cyberhive-public" {
  vpc_id = aws_vpc.cyberhive.id
  tags = {
    Name = "CyberHive-Public-RT"
    Terraform = "true"
    Project = "CyberHive"
    Requestor = "Sarah Blundell"
  }
}

# Create a route for the public route table to the internet gateway
resource "aws_route" "cyberhive-public" {
  route_table_id = aws_route_table.cyberhive-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.cyberhive.id
}

# Associate the public subnets with the public route table
resource "aws_route_table_association" "cyberhive-public-1" {
  subnet_id = aws_subnet.cyberhive-public-1.id
  route_table_id = aws_route_table.cyberhive-public.id
}

resource "aws_route_table_association" "cyberhive-public-2" {
  subnet_id = aws_subnet.cyberhive-public-2.id
  route_table_id = aws_route_table.cyberhive-public.id
}

resource "aws_route_table_association" "cyberhive-public-3" {
  subnet_id = aws_subnet.cyberhive-public-3.id
  route_table_id = aws_route_table.cyberhive-public.id
}

# Create a KMS Key for the new account
resource "aws_kms_key" "cyberhive" {
  description = "CyberHive KMS Key"
  enable_key_rotation = true
  is_enabled = true
  tags = {
    Name = "CyberHive-KMS-Key"
    Terraform = "true"
    Project = "CyberHive"
    Requestor = "Sarah Blundell"
  }
}

# Create SSH key pair for the new account
resource "tls_private_key" "cyberhive" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "cyberhive" {
  key_name = "cyberhive"
  public_key = tls_private_key.cyberhive.public_key_openssh
}

# Output the SSH private key
output "cyberhive_ssh_private_key" {
  value = tls_private_key.cyberhive.private_key_pem
  sensitive = true
}

# Create a security group for the EC2 instance and allow SSH, HTTP, and HTTPS traffic in from the internet
resource "aws_security_group" "cyberhive" {
  name = "CyberHive-SG"
  description = "CyberHive Security Group"
  vpc_id = aws_vpc.cyberhive.id
  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "CyberHive-SG"
    Terraform = "true"
    Project = "CyberHive"
    Requestor = "Sarah Blundell"
  }
}

# Create an free tier EC2 instance running Ubuntu with an EBS volume for the root file system encrypted with a customer-managed KMS key
resource "aws_instance" "cyberhive" {
  ami = "ami-0f540e9f488cfa27d"
  instance_type = "t2.micro"
  key_name = aws_key_pair.cyberhive.key_name
  subnet_id = aws_subnet.cyberhive-public-1.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.cyberhive.id]
  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    encrypted = true
    kms_key_id = aws_kms_key.cyberhive.id
  }
  tags = {
    Name = "CyberHive-EC2-WebServer"
    Terraform = "true"
    Project = "CyberHive"
    Requestor = "Sarah Blundell"
    Role = "WebServer"
    OS = "Ubuntu"
    SSH_KEY = aws_key_pair.cyberhive.key_name
  }
}

# Create an elastic IP address for the EC2 instance
resource "aws_eip" "cyberhive" {
  vpc = true
  instance = aws_instance.cyberhive.id
  tags = {
    Name = "CyberHive-EC2-WebServer-EIP"
    Terraform = "true"
    Project = "CyberHive"
    Requestor = "Sarah Blundell"
  }
}

# Output the public IP address of the EC2 instance
output "cyberhive_public_ip" {
  value = aws_eip.cyberhive.public_ip
}