variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair in AWS"
  type        = string
  default     = "todo-app-key"
}

variable "public_key_path" {
  description = "Path to the public SSH key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Path to the private SSH key file (for Ansible)"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "server_user" {
  description = "User to log into the server"
  type        = string
  default     = "ubuntu"
}

variable "ssh_cidr" {
  description = "CIDR block to allow SSH access from"
  type        = string
  default     = "0.0.0.0/0"
}
