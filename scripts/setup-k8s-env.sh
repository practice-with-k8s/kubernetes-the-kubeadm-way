#!/bin/bash

#disable swap
swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Add br_netfilter kernel module
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

#install containerd, runc
CONTAINERD_VERSION=1.6.8
CNI_VERSION=1.1.1
RUNC_VERSION=1.1.4
wget -q --show-progress --https-only --timestamping \
  https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz \
  https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz \
  https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64

mkdir -p \
/usr/local/lib/systemd/system/ \
/opt/cni/bin/ \
/etc/containerd/

wget -O /usr/local/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

install -m 755 runc.amd64 /usr/local/sbin/runc
tar -xzvf containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz -C /usr/local
tar -xzvf cni-plugins-linux-amd64-v${CNI_VERSION}.tgz -C /opt/cni/bin

containerd config default > /etc/containerd/config.toml
sed -i '/SystemdCgroup/s/false/true/' /etc/containerd/config.toml
systemctl daemon-reload
systemctl enable --now containerd

#install kubeadm, kubelet, kubectl
KUBERNETES_VERSION=1.25.2-00
apt-get update
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet=${KUBERNETES_VERSION} kubeadm=${KUBERNETES_VERSION} kubectl=${KUBERNETES_VERSION}
apt-mark hold kubelet kubeadm kubectl

mkdir -p /etc/kubernetes/pki/etcd
