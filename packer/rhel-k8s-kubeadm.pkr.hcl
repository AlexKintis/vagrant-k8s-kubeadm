packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1"
    }
  }
}

variable "box_name" {
  type    = string
  default = "almalinux/9"
}

variable "user" {
  type    = string
  default = "vagrant"
}

source "vagrant" "input_rhel_box_source" {
  communicator = "ssh"
  source_path  = var.box_name 
  provider = "virtualbox"
  add_force = true
}

build {
  sources = ["source.vagrant.input_rhel_box_source"]

  #provisioner "shell" {
    #execute_command = "echo '${var.user}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    #scripts         = ["./scripts/sysctl_conf.sh"]
  #}

  #provisioner "shell" {
    #execute_command = "echo '${var.user}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    #inline          = ["sysctl --system"]
  #}

  provisioner "shell" {
    inline         =  [ "echo \"set -o vi\" >> ~/.bashrc" ]
  }

  provisioner "shell" {
    execute_command = "echo '${var.user}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    scripts         = ["./scripts/install-k8s-kubeadm.sh"]
  }
}
