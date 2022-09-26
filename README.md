# Bootstraping Kubernetes cluster using Kubeadm in Virtualbox using Vagrant

## To create the cluster, run this command on master-1
```
sudo kubeadm init --config=/etc/kubernetes/kubeadmcfg.yaml
```

## Install Weave pod network
```
echo "s3cr3tp4ssw0rd" > /var/lib/weave/weave-passwd
kubectl create secret -n kube-system generic weave-passwd --from-file=/var/lib/weave/weave-passwd
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&password-secret=weave-passwd&env.IPALLOC_RANGE=10.100.0.0/16"
```

## Print command to join worker nodes. To join the worker nodes, run the `output` of the below command on the worker nodes
```
kubeadm token create --print-join-command
```

## Print the cert to join the control nodes.
```
sudo kubeadm init phase upload-certs --upload-certs --config=/etc/kubernetes/kubeadmcfg.yaml
```