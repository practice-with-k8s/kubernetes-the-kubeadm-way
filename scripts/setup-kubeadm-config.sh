#!/bin/bash

cat << EOF > /etc/kubernetes/kubeadmcfg.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: "192.168.203.2:6443" # change this (see below)
etcd:
  external:
    endpoints:
      - https://192.168.203.5:2379 # change ETCD_1_IP appropriately
      - https://192.168.203.6:2379 # change ETCD_2_IP appropriately
      - https://192.168.203.7:2379 # change ETCD_3_IP appropriately
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
    keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
networking:
    serviceSubnet: 10.200.0.0/16
    podSubnet: 10.100.0.0/16
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
    advertiseAddress: 192.168.203.11
EOF