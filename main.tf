provider "aws" {
  region = "eu-west-1"
}

// Creating the VPC
resource "aws_vpc" "vpc" {
  cidr_block       = "11.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC"
  }
}

// Creating the public subnet
resource "aws_subnet" "public-subnet" {
  vpc_id                  = "vpc-0260b96c849939812"
  cidr_block              = "11.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"
  tags = {
    Name = "Public-subnet"
  }
}
//creating private subnet

resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "11.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1b"
  tags = {
    Name = "Private-subnet"
  }
}
//creating internet gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw-terraform"
  }
}
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Route to internet"
  }
}
resource "aws_route_table_association" "rt-1" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.route.id

}
resource "aws_security_group" "sg" {
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG"
  }
}

resource "aws_instance" "ubuntu" {
  ami                         = "ami-0776c814353b4814d"
  instance_type               = "t2.micro"
  key_name                    = "Ireland"
  security_groups             = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.public-subnet.id
  associate_public_ip_address = true
  user_data                   = <<-EOF
                  #!/bin/bash
                  apt update -y
                  apt install -y apache2
                  systemctl start apache2
                  systemctl enable apache2
                  EOF
  tags = {
    Name = "Ubuntu-server"
  }

}
output "public_ip_ubuntu" {
  value = aws_instance.ubuntu.public_ip
}
//creating network interface
resource "aws_network_interface" "network" {
   subnet_id       = aws_subnet.public-subnet.id 
  private_ips     = ["11.0.0.200"]  
  security_groups = [aws_security_group.sg.id]  
}
//creating elastic ip
resource "aws_eip" "eip" {
  vpc = true
  instance = aws_instance.ubuntu.id
}
//eip association
resource "aws_eip_association" "eip1" {
  instance_id   = aws_instance.ubuntu.id
  allocation_id = aws_eip.eip.id
  network_interface_id = aws_network_interface.network.id
}
// creating a bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "my-terraform-created-08"
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket1" {
  depends_on = [
    aws_s3_bucket_ownership_controls.ownership,
    aws_s3_bucket_public_access_block.public_access,
  ]

  bucket = aws_s3_bucket.bucket.id
  acl    = "public-read"
  
}
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = "terraform-state-lock-dynamo"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20
  attribute {
    name = "LockID"
    type = "S"
  }
}
terraform {
  backend "s3" {
    bucket = "my-terraform-created-08"
    dynamodb_table = "terraform-state-lock-dynamo"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}