# Trigger drift detection test 2
terraform {
  required_version = ">= 1.0.0"
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
    local = {
      source = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

provider "null" {}
provider "local" {}

variable "ssh_host" {
  description = "The public IP of the Contabo VPS"
  type        = string
}

variable "ssh_user" {
  description = "The SSH user"
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  description = "Path to the private key file"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "leonesii.mooo.com"
}

variable "email" {
  description = "Email for SSL certificates"
  type        = string
  default     = "yhungdew@gmail.com"
}

resource "null_resource" "vps_provisioner" {
  triggers = {
    # Trigger on any change to the ansible playbook or roles
    playbook_hash = sha256(file("${path.module}/../ansible/playbook.yml"))
    # Also trigger if variables change
    host = var.ssh_host
  }

  # Provision the server (simulated provisioning since it exists)
  # Using local-exec to bypass potential Go SSH lib issues since manual SSH works
  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key} ${var.ssh_user}@${var.ssh_host} 'echo Server is reachable && uptime'"
  }
}

# Generate Ansible Inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    host = var.ssh_host
    user = var.ssh_user
    key  = var.ssh_private_key
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

# Run Ansible after inventory is generated
resource "null_resource" "run_ansible" {
  depends_on = [local_file.ansible_inventory, null_resource.vps_provisioner]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${path.module}/../ansible/inventory.ini ${path.module}/../ansible/playbook.yml --extra-vars 'domain_name=${var.domain_name} email=${var.email}'"
  }
}
