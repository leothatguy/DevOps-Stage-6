# test 2
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# Security Group
resource "aws_security_group" "todo_app" {
  name        = "todo-app-sg"
  description = "Security group for TODO application"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "todo-app-sg"
  }
}

# EC2 Instance
resource "aws_instance" "todo_app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.todo_app.id]

  tags = {
    Name        = "todo-app-server"
    Environment = "production"
    Project     = "hngi13-stage6"
  }
}

# Generate Ansible Inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    host = aws_instance.todo_app.public_ip
    user = var.server_user
    key  = var.private_key_path
  })
  filename = "${path.module}/../ansible/inventory/hosts.yml"
}

# Trigger Ansible Provisioning
resource "null_resource" "ansible_provision" {
  triggers = {
    instance_id = aws_instance.todo_app.id
    inventory   = local_file.ansible_inventory.content
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for SSH to be available..."
      # Simple wait loop for SSH
      for i in {1..30}; do
        nc -z -w 5 ${aws_instance.todo_app.public_ip} 22 && break
        echo "Waiting for port 22..."
        sleep 10
      done

      echo "Running Ansible playbook..."
      # Set strict host key checking to no to avoid interactive prompt
      export ANSIBLE_HOST_KEY_CHECKING=False
      ansible-playbook -i ${path.module}/../ansible/inventory/hosts.yml ${path.module}/../ansible/playbook.yml
    EOT
  }

  depends_on = [
    aws_instance.todo_app,
    local_file.ansible_inventory
  ]
}
