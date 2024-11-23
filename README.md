# Kubernetes Cluster Setup with Vagrant and VirtualBox

This project provides an automated way to set up a Kubernetes cluster using Vagrant, VirtualBox, and kubeadm. The setup includes one master node and two worker nodes, each provisioned with the necessary tools and configurations for a functional Kubernetes environment. This README provides detailed instructions on how to use this setup.

## Prerequisites

Before you get started, ensure that you have the following installed on your system:

1. **Vagrant**: [Download and install Vagrant](https://www.vagrantup.com/downloads).
2. **VirtualBox**: [Download and install VirtualBox](https://www.virtualbox.org/wiki/Downloads).
3. **Packer**: This project uses a base box created by Packer. Ensure that the `BASE_BOX` defined in the `Vagrantfile` is correctly built before proceeding.
4. **Editor**: You can use any text editor of your choice to modify the configuration files.

## Project Structure

- **Vagrantfile**: This file contains the configuration for setting up the master and worker nodes of the Kubernetes cluster.
- **scripts/install-k8s-kubeadm.sh**: This script installs Kubernetes components such as kubeadm, kubelet, and kubectl.
- **kubeadm_join_cmd.sh**: This script is dynamically generated and contains the command for worker nodes to join the cluster.

## Setting Up the Kubernetes Cluster

1. **Clone the Repository**

   Clone this repository to your local machine:

   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Build the Base Box with Packer**

   Before running Vagrant, you need to create the base box using Packer. This box is used to provision the master and worker nodes:

   ```bash
   cd packer
   packer build rhel-k8s-kubeadm.pkr.hcl
   ```

   Ensure that the output box file path matches the value defined in `BASE_BOX` inside the `Vagrantfile` (eg. `packer/output-input_rhel_box_source/package.box`).

3. **Start the Cluster**

   To bring up the Kubernetes cluster, run:

   ```bash
   vagrant up
   ```

   This command will set up the following nodes:

   - **k8s-master**: Kubernetes master node that initializes the cluster.
   - **k8s-worker-1** and **k8s-worker-2**: Worker nodes that will join the Kubernetes cluster.
   - Apply the nginx-deployment.yaml to all nodes throught the master node.

   The process includes installing all required packages, initializing the Kubernetes master, and configuring worker nodes to join the cluster.

4. **Verify the Cluster**

   Once the setup is complete, SSH into the master node and check the status of the cluster:

   ```bash
   vagrant ssh k8s-master
   sudo kubectl get nodes
   ```

   You should see the master and both worker nodes in a `Ready` state.

   Validate Kubernetes Deployment

   ```sh
   # Step 1: Check the Status of the Deployment
   sudo kubectl get deployments
   ```

   **Expected Output**:

   ```
   NAME               READY   UP-TO-DATE   AVAILABLE   AGE
   nginx-deployment   3/3     3            3           1m
   ```

   ```sh
   # Step 2: Check the Pods Status
   sudo kubectl get pods
   ```

   **Expected Output**:

   ```
   NAME                                READY   STATUS    RESTARTS   AGE
   nginx-deployment-xxxxx-yyyyy        1/1     Running   0          1m
   nginx-deployment-xxxxx-zzzzz        1/1     Running   0          1m
   nginx-deployment-xxxxx-aaaaa        1/1     Running   0          1m
   ```

   ```sh
   # Step 3: Describe the Deployment (Optional)
   sudo kubectl describe deployment nginx-deployment
   ```

   **Expected Output**: Contains no warnings or errors in the `Events` section.

   ```sh
   # Step 4: Check the Service
   kubectl get services
   ```

   **Expected Output**:

   ```
    NAME            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
    kubernetes      ClusterIP   10.96.0.1     <none>        443/TCP        1m
    nginx-service   NodePort    10.96.53.57   <none>        80:30001/TCP   1m
   ```

   ```sh
   # Step 5: Verify the Deployment Rollout Status
   sudo kubectl rollout status deployment/nginx-deployment
   ```

   **Expected Output**:

   ```
   deployment "nginx-deployment" successfully rolled out
   ```

5. **Access the Nginx deployment**

    Use the browser to access the Nginx deployment through the worker and master nodes:

    ```
    http://192.168.56.10:30001/
    http://192.168.56.11:30001/
    http://192.168.56.12:30001/
    ```

    You should see the Nginx welcome page in all of the above URLs.

## Node Configuration Details

- **Master Node** (`k8s-master`):
  - **IP Address**: 192.168.56.10
  - **Resources**: 2048 MB memory, 2 CPUs
  - **Roles**: Control plane, cluster manager

- **Worker Node 1** (`k8s-worker-1`):
  - **IP Address**: 192.168.56.11
  - **Resources**: 2048 MB memory, 2 CPUs
  - **Roles**: Cluster worker

- **Worker Node 2** (`k8s-worker-2`):
  - **IP Address**: 192.168.56.12
  - **Resources**: 2048 MB memory, 2 CPUs
  - **Roles**: Cluster worker

## Networking

The cluster uses a **private network** configuration, with IP addresses assigned to each node as specified in the `Vagrantfile`. The **Calico** network plugin is used to configure pod networking, allowing communication between pods across different nodes.

## Key Configuration Steps

1. **Master Node Initialization**:
   - The master node is initialized using `kubeadm init`, which sets up the control plane components.
   - The pod network CIDR is set to `192.168.0.0/16`, which is required for configuring the Calico network.

2. **Worker Node Join**:
   - The `kubeadm join` command is generated by the master node during initialization and stored in the `kubeadm_join_cmd.sh` file.
   - This command is executed by the worker nodes to join the cluster.

3. **Calico Pod Network**:
   - After initializing the master node, Calico is applied as the pod network using `kubectl apply` to ensure that the nodes can communicate with each other.

## Vagrant Common Commands

- **SSH into a Node**:

  ```bash
  vagrant ssh [ k8s-master, k8s-worker-1, k8s-worker-2 ]
  ```

  Example:

  ```bash
  vagrant ssh k8s-master
  ```

- **Destroy the Cluster**:
  If you want to tear down the cluster, use the following command:

  ```bash
  vagrant destroy -f
  ```

- **Rebuild the Cluster**:
  You can rebuild the cluster after destroying it by running:

  ```bash
  vagrant up
  ```

## Troubleshooting

1. **Kubelet Failing to Start**:
   - Ensure that the network settings (such as the pod network CIDR) are correctly configured.
   - Verify that the base box was correctly built with all required dependencies.

2. **Worker Nodes Not Joining**:
   - Check the contents of the `kubeadm_join_cmd.sh` file. Make sure it contains the correct join command.
   - Make sure the worker nodes have network access to the master node.

3. **Calico Network Plugin Issues**:
   - Sometimes the Calico plugin may take a while to initialize. You can verify the status by running:

   ```bash
   kubectl get pods -n kube-system
   ```

   - Ensure all Calico components are in the `Running` state.

## Notes

- This setup is intended as an example, development and testing purposes only. It is not suitable for production environments.
- You can modify the memory and CPU allocations in the `Vagrantfile` to suit your hardware.
- Make sure your system supports virtualization and has enough resources to allocate to the VMs.
