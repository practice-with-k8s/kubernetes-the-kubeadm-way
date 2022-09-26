# -*- mode: ruby -*-
# vi:set ft=ruby sw=2 ts=2 sts=2:

# Define the number of master and worker nodes
# If this number is changed, remember to update setup-hosts.sh script with the new hosts IP details in /etc/hosts of each VM.
NUM_MASTER_NODE = 2
NUM_WORKER_NODE = 1
NUM_ETCD_NODE = 3

IP_NW = "192.168.203."
MASTER_IP_START = 10
NODE_IP_START = 20
ETCD_IP_START = 4
LB_IP_START = 2

# Sets up hosts file and DNS
def setup_dns(node)
  # Set up /etc/hosts
  node.vm.provision "setup-hosts", :type => "shell", :path => "scripts/setup-hosts.sh" do |s|
    s.args = ["enp0s8", node.vm.hostname]
  end
  # Set up DNS resolution
  node.vm.provision "setup-dns", type: "shell", :path => "scripts/update-dns.sh"
end

# Runs provisioning steps that are required by masters and workers
def provision_kubernetes_node(node)

  # Set up kernel parameters, modules and tunables
  node.vm.provision "setup-k8s-env", :type => "shell", :path => "scripts/setup-k8s-env.sh"

  # Set up DNS
  setup_dns node
end


# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  # config.vm.box = "base"
  config.vm.box = "ubuntu/focal64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  config.vm.box_check_update = false


  #append personal public key to guests
  config.vm.provision "shell" do |s|
    ssh_pub_key = File.readlines(".vagrant/vagrant.pem.pub").first.strip
    s.inline = <<-SHELL
      echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
      echo #{ssh_pub_key} >> /root/.ssh/authorized_keys
      cp /vagrant/.vagrant/vagrant.pem /home/vagrant/.ssh/id_rsa
      cp /vagrant/.vagrant/vagrant.pem /root/.ssh/id_rsa
      chown vagrant.vagrant /home/vagrant/.ssh/id_rsa
      chmod 600 /home/vagrant/.ssh/id_rsa
      chmod 600 /root/.ssh/id_rsa
    SHELL
  end

  

  # Provision Master Nodes
  (1..NUM_MASTER_NODE).each do |i|
    config.vm.define "master-#{i}" do |node|
      # Name shown in the GUI
      node.vm.provider "virtualbox" do |vb|
        vb.name = "kubernetes-ha-master-#{i}"
        vb.memory = 2048
        vb.cpus = 2
      end
      node.vm.hostname = "master-#{i}"
      node.vm.network :private_network, ip: IP_NW + "#{MASTER_IP_START + i}"
      node.vm.network "forwarded_port", guest: 22, host: "#{2710 + i}"
      provision_kubernetes_node node
      if i == 1
        node.vm.provision "setup-kubeadm-config", :type => "shell", :path => "scripts/setup-kubeadm-config.sh"
      end
    end
  end

  # Provision Worker Nodes
  (1..NUM_WORKER_NODE).each do |i|
    config.vm.define "worker-#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "kubernetes-ha-worker-#{i}"
        vb.memory = 512
        vb.cpus = 1
      end
      node.vm.hostname = "worker-#{i}"
      node.vm.network :private_network, ip: IP_NW + "#{NODE_IP_START + i}"
      node.vm.network "forwarded_port", guest: 22, host: "#{2720 + i}"
      provision_kubernetes_node node
    end
  end

    # Provision ETCD Nodes
  (1..NUM_ETCD_NODE).each do |i|
    config.vm.define "etcd-#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "kubernetes-ha-etcd-#{i}"
        vb.memory = 512
        vb.cpus = 1
      end
      node.vm.hostname = "etcd-#{i}"
      node.vm.network :private_network, ip: IP_NW + "#{ETCD_IP_START + i}"
      node.vm.network "forwarded_port", guest: 22, host: "#{2704 + i}"
      provision_kubernetes_node node
      node.vm.provision "setup-etcd-kubelet", :type => "shell", :path => "scripts/setup-etcd-kubelet.sh"
      if i == NUM_ETCD_NODE
        node.vm.provision "setup-etcd-cluster", :type => "shell", :path => "scripts/setup-etcd-cluster.sh"
      end
    end
  end
  
  # Provision Load Balancer Node
  config.vm.define "loadbalancer" do |node|
    node.vm.provider "virtualbox" do |vb|
      vb.name = "kubernetes-ha-lb"
      vb.memory = 512
      vb.cpus = 1
    end
    node.vm.hostname = "loadbalancer"
    node.vm.network :private_network, ip: IP_NW + "#{LB_IP_START}"
    node.vm.network "forwarded_port", guest: 22, host: 2702
    node.vm.provision "setup-nginx", :type => "shell", :path => "scripts/setup-nginx.sh"
    setup_dns node
  end
  
end
