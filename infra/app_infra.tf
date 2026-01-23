terraform {
  required_providers {
    aws   = { source = "hashicorp/aws", version = "~> 6.0" }
  }
  # We will add S3 backend here later. For now, local state is fine for testing.
}

provider "aws" {
  region = "us-east-1"
}

# --- DATA SOURCES (FINDING EXISTING RESOURCES) ---
# This tells Terraform: "Go find the VPC named '3-tier-vpc' that we already made."
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["3-tier-vpc"]
  }
}

data "aws_security_group" "universal_sg" {
  filter {
    name   = "tag:Name"
    values = ["Universal-SG"]
  }
  vpc_id = data.aws_vpc.selected.id
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

# --- APP INFRASTRUCTURE ---

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# We reuse the SAME key pair name because Jenkins has the private key for it
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.web.id
  vpc_security_group_ids = [data.aws_security_group.universal_sg.id]
  key_name               = "three-tier-key" 
  
  # IMPORTANT: Jenkins will pull this repo. 
  # Ensure setup_web.sh is in the 'infra' folder of your repo.
  user_data              = file("setup_web.sh")
  
  tags = { Name = "Web-Server" }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.app.id
  vpc_security_group_ids = [data.aws_security_group.universal_sg.id]
  key_name               = "three-tier-key"
  user_data              = file("setup_app.sh")
  tags = { Name = "App-Server" }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.db.id
  vpc_security_group_ids = [data.aws_security_group.universal_sg.id]
  key_name               = "three-tier-key"
  user_data              = file("setup_db.sh")
  tags = { Name = "DB-Server" }
}

# --- OUTPUTS (For Jenkins to use) ---
output "app_private_ip" {
  value = aws_instance.app.private_ip
}
output "web_private_ip" {
  value = aws_instance.web.private_ip
terraform {
  required_providers {
    aws   = { source = "hashicorp/aws", version = "~> 6.0" }
  }
  # We will add S3 backend here later. For now, local state is fine for testing.
}

provider "aws" {
  region = "us-east-1"
}

# --- DATA SOURCES (FINDING EXISTING RESOURCES) ---
# This tells Terraform: "Go find the VPC named '3-tier-vpc' that we already made."
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["3-tier-vpc"]
  }
}

data "aws_security_group" "universal_sg" {
  filter {
    name   = "tag:Name"
    values = ["Universal-SG"]
  }
  vpc_id = data.aws_vpc.selected.id
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

# --- APP INFRASTRUCTURE ---

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# We reuse the SAME key pair name because Jenkins has the private key for it
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.web.id
  vpc_security_group_ids = [data.aws_security_group.universal_sg.id]
  key_name               = "three-tier-key" 
  
  # IMPORTANT: Jenkins will pull this repo. 
  # Ensure setup_web.sh is in the 'infra' folder of your repo.
  user_data              = file("setup_web.sh")
  
  tags = { Name = "Web-Server" }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.app.id
  vpc_security_group_ids = [data.aws_security_group.universal_sg.id]
  key_name               = "three-tier-key"
  user_data              = file("setup_app.sh")
  tags = { Name = "App-Server" }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.db.id
  vpc_security_group_ids = [data.aws_security_group.universal_sg.id]
  key_name               = "three-tier-key"
  user_data              = file("setup_db.sh")
  tags = { Name = "DB-Server" }
}

# --- OUTPUTS (For Jenkins to use) ---
output "app_private_ip" {
  value = aws_instance.app.private_ip
}
output "web_private_ip" {
  value = aws_instance.web.private_ip
}}
