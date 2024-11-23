# -*- mode: ruby -*-
# vi: set ft=ruby :

BASE_BOX = "packer/output-input_rhel_box_source/package.box"

Vagrant.configure("2") do |config|

  # Master Node Configuration
  config.vm.define "k8s-master" do |master|

    node_ip = "192.168.56.10"

    # Set the base box to be used for the master node
    master.vm.box = BASE_BOX
    master.vm.hostname = "k8s-master"  # Set the hostname for the master node
    master.vm.network "private_network", ip: node_ip  # Configure a private network with a specific IP address

    # Set resources for the VirtualBox provider
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"  # Allocate 2048 MB of memory to the master node
      vb.cpus = 2  # Assign 2 CPUs to the master node
    end

    # Provision the master node using kubeadm to initialize the cluster
    master.vm.provision "kubeadm_init", type: "shell", 
      privileged: true,
      args: [node_ip],
      inline: <<-SHELL
      local_ip="$1"

      # Write the local IP address to the kubelet default configuration file
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF

      # Initialize the Kubernetes cluster with kubeadm
      kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$local_ip | tee /tmp/kubeadm-init.out

      # Set up the kubeconfig file for the current user
      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config
      
      # Start the kubelet service and enable it to start at boot
      systemctl enable --now kubelet

      # Extract the kubeadm join command for worker nodes and save it to a shared location
      grep "kubeadm join" -A 1 /tmp/kubeadm-init.out > /vagrant/kubeadm_join_cmd.sh
      rm /tmp/kubeadm-init.out
    SHELL

    # Apply Calico as the pod network
    master.vm.provision "apply_calico", type: "shell", 
      privileged: true,
      inline: <<-SHELL
      # Sleep for 30 seconds to wait for the kubelet service to start
      # sleep 30
      # Apply the Calico network plugin to the cluster
      kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/refs/heads/master/manifests/calico.yaml
    SHELL

    # Apply Nginx Deployment after all nodes are initialized
    master.vm.provision "apply_nginx", type: "shell", 
      privileged: true,
      inline: <<-SHELL
      kubectl apply -f /vagrant/nginx-deployment.yaml
    SHELL

  end

  # Worker Node 1 Configuration
  config.vm.define "k8s-worker-1" do |worker|

    # Set the base box to be used for the worker node
    worker.vm.box = BASE_BOX
    worker.vm.hostname = "k8s-worker-1"  # Set the hostname for the worker node
    worker.vm.network "private_network", ip: "192.168.56.11"  # Configure a private network with a specific IP address

    # Set resources for the VirtualBox provider
    worker.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"  # Allocate 2048 MB of memory to the worker node
      vb.cpus = 2  # Assign 2 CPUs to the worker node
    end

    # Enable and start the kubelet service on the worker node
    worker.vm.provision "enable_kubelet",
      type: "shell",
      privileged: true,
      inline: <<-SHELL
      systemctl enable --now kubelet
    SHELL

    # Join the worker node to the Kubernetes cluster using the kubeadm join command
    worker.vm.provision "join_to_cluster",
      type: "shell", 
      privileged: true,
      path: "kubeadm_join_cmd.sh"
  end

  # Worker Node 2 Configuration
  config.vm.define "k8s-worker-2" do |worker|
    # Set the base box to be used for the worker node
    worker.vm.box = BASE_BOX
    worker.vm.hostname = "k8s-worker-2"  # Set the hostname for the worker node
    worker.vm.network "private_network", ip: "192.168.56.12"  # Configure a private network with a specific IP address
    
    # Set resources for the VirtualBox provider
    worker.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"  # Allocate 2048 MB of memory to the worker node
      vb.cpus = 2  # Assign 2 CPUs to the worker node
    end

    # Enable and start the kubelet service on the worker node
    worker.vm.provision "enable_kubelet",
      type: "shell",
      privileged: true,
      inline: <<-SHELL
      systemctl enable --now kubelet
    SHELL

    # Join the worker node to the Kubernetes cluster using the kubeadm join command
    worker.vm.provision "join_to_cluster",
      type: "shell", 
      privileged: true,
      path: "kubeadm_join_cmd.sh"
  end

end
