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

# Define the variables used in the Packer template
variable "box_name" {
  type    = string
  default = "almalinux/9"  # Name of the base Vagrant box to use
}

variable "user" {
  type    = string
  default = "vagrant"  # Default username for the box
}

# Define the Vagrant source box configuration
source "vagrant" "input_rhel_box_source" {
  communicator = "ssh"  # Use SSH for connecting to the instance
  source_path  = var.box_name  # Specify the Vagrant box to be used
  provider = "virtualbox"  # Provider to use for the Vagrant box (VirtualBox)
  add_force = true  # Force add the box even if it already exists
}

# Define the build process
build {
  sources = ["source.vagrant.input_rhel_box_source"]  # Use the defined Vagrant source as the input

  # Provisioner to configure shell settings
  provisioner "shell" {
    inline         =  [ "echo \"set -o vi\" >> ~/.bashrc" ]  # Add "set -o vi" to the user's bashrc to enable vi mode
  }

  # Provisioner to run an external shell script as root
  provisioner "shell" {
    execute_command = "echo '${var.user}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"  # Run the script with sudo privileges using the default user password
    scripts         = ["./scripts/install-k8s-kubeadm.sh"]  # Path to the script for installing Kubernetes components
  }
}
