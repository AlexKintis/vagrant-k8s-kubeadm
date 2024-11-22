#!/usr/bin/env bash

set -euxo pipefail
# Enable strict mode:
# -e: Exit immediately if a command fails.
# -u: Treat unset variables as an error.
# -x: Print each command before executing it.
# -o pipefail: Return exit code of the last command in the pipeline that failed.

# Disable swap (required for Kubernetes installation)
swapoff -a
# Permanently disable swap by commenting out the swap line in /etc/fstab
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Disable SELinux (required for Kubernetes)
setenforce 0
# Make SELinux disabled permanently by modifying its configuration
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

# Load necessary kernel modules for Kubernetes networking
modprobe overlay
modprobe br_netfilter

# Ensure the modules are loaded on boot by adding them to /etc/modules-load.d/k8s.conf
tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

# Set required sysctl parameters for Kubernetes networking
tee /etc/sysctl.d/k8s.conf <<EOT
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOT

# Reload sysctl to apply the new kernel parameters
sysctl --system

# Install Docker's prerequisites (dnf plugins)
dnf install -y dnf-plugins-core
# Add Docker's official repository for CentOS
# This repository is required to install Docker components
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker components
# docker-ce: Docker Engine - Community
# docker-ce-cli: Command Line Interface for Docker
# containerd.io: Container runtime required for Kubernetes
dnf install -y docker-ce docker-ce-cli containerd.io

# Create a default configuration for containerd and redirect output to /etc/containerd/config.toml
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
# Modify containerd configuration to enable SystemdCgroup (required for Kubernetes compatibility)
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# Enable and start Docker as a system service
systemctl enable docker
systemctl start docker

# Add Kubernetes repository to /etc/yum.repos.d/kubernetes.repo
# This overwrites any existing Kubernetes configuration in the yum repository list
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# Install Kubernetes components (kubelet, kubeadm, kubectl) while disabling any conflicting packages
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
