terraform {
  required_providers {
    aws   = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --- DATA SOURCES (Connects to the Backbone) ---
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["3-tier-vpc"]
  }
}

data "aws_subnet" "web" {
  filter {
    name   = "tag:Name"
    values = ["Web-Public"]
  }
  vpc_id = data.aws_vpc.selected.id
}

data "aws_subnet" "app" {
  filter {
    name   = "tag:Name"
    values = ["App-Public-Debug"]
  }
  vpc_id = data.aws_vpc.selected.id
}

data "aws_subnet" "db" {
  filter {
    name   = "tag:Name"
    values = ["DB-Public-Debug"]
  }
  vpc_id = data.aws_vpc.selected.id
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- SECURITY GROUPS (Tiered & Secure) ---
resource "aws_security_group" "web_sg" {
  name   = "web-tier-sg"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name   = "app-tier-sg"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name   = "db-tier-sg"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- INSTANCES (With Static IPs) ---
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.web.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "three-tier-key"
  private_ip             = "10.0.1.191"
  user_data              = file("${path.module}/setup_web.sh")
  
  root_block_device {

    volume_size = 10

    volume_type = "gp3"

    encrypted   = true

  }

  tags                   = { Name = "Web-Server" }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.app.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = "three-tier-key"
  private_ip             = "10.0.2.150"
  user_data              = file("${path.module}/setup_app.sh")

  root_block_device {

    volume_size = 10

    volume_type = "gp3"

    encrypted   = true

  }

  tags                   = { Name = "App-Server" }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.db.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = "three-tier-key"
  private_ip             = "10.0.3.179"
  user_data              = file("${path.module}/setup_db.sh")
  
  root_block_device {

    volume_size = 10

    volume_type = "gp3"

    encrypted   = true

  }

  tags                   = { Name = "DB-Server" }
}

# --- EIPs (Public Access) ---
resource "aws_eip" "web_eip" {
  instance = aws_instance.web.id
  domain   = "vpc"
}

resource "aws_eip" "app_eip" {
  instance = aws_instance.app.id
  domain   = "vpc"
}

resource "aws_eip" "db_eip" {
  instance = aws_instance.db.id
  domain   = "vpc"
}

# --- OUTPUTS ---
output "app_private_ip" {
  value = aws_instance.app.private_ip
}
output "web_private_ip" {
  value = aws_instance.web.private_ip
}
