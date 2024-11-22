# -*- mode: ruby -*-
# vi: set ft=ruby :

BASE_BOX = "packer/output-input_rhel_box_source/package.box"

Vagrant.configure("2") do |config|

  # Master Node Configuration
  config.vm.define "k8s-master" do |master|

    node_ip = "192.168.56.10"

    master.vm.box = BASE_BOX
    master.vm.hostname = "k8s-master"
    master.vm.network "private_network", ip: node_ip

    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end

    master.vm.provision "kubeadm_init", type: "shell", 
      privileged: true,
      args: [node_ip],
      inline: <<-SHELL
      local_ip="$1"

      # Write the local IP address to the kubelet default configuration file
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF

      kubeadm init --pod-network-cidr=192.168.0.0/16 | tee /tmp/kubeadm-init.out

      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config
      
      # Start the kubelet service
      systemctl enable --now kubelet
      grep "kubeadm join" -A 1 /tmp/kubeadm-init.out > /vagrant/kubeadm_join_cmd.sh
      rm /tmp/kubeadm-init.out
    SHELL

    master.vm.provision "apply_calico", type: "shell", 
      privileged: true,
      inline: <<-SHELL
      # Sleep for 30 seconds to wait for the kubelet service to start
      # sleep 30
      kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/refs/heads/master/manifests/calico.yaml
    SHELL

  end

  # Worker Node 1 Configuration
  config.vm.define "k8s-worker-1" do |worker|

    worker.vm.box = BASE_BOX
    worker.vm.hostname = "k8s-worker-1"
    worker.vm.network "private_network", ip: "192.168.56.11"

    worker.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end

    worker.vm.provision "enable_kubelet",
      type: "shell",
      privileged: true,
      inline: <<-SHELL
      systemctl enable --now kubelet
    SHELL

    worker.vm.provision "join_to_cluster",
      type: "shell", 
      privileged: true,
      path: "kubeadm_join_cmd.sh"
  end

  # Worker Node 2 Configuration
  config.vm.define "k8s-worker-2" do |worker|
    worker.vm.box = BASE_BOX
    worker.vm.hostname = "k8s-worker-2"
    worker.vm.network "private_network", ip: "192.168.56.12"
    worker.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end

    worker.vm.provision "enable_kubelet",
      type: "shell",
      privileged: true,
      inline: <<-SHELL
      systemctl enable --now kubelet
    SHELL

    worker.vm.provision "join_to_cluster",
      type: "shell", 
      privileged: true,
      path: "kubeadm_join_cmd.sh"
  end

end
