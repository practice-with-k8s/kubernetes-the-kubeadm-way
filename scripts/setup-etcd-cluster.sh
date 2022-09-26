kubeadm init phase certs etcd-ca

HOSTS=($(awk '/etcd/{print $1}' /etc/hosts))
NAMES=($(awk '/etcd/{print $2}' /etc/hosts))

mkdir -p /etc/kubernetes/etcd

for i in "${!NAMES[@]}"; do
HOST=${HOSTS[$i]}
NAME=${NAMES[$i]}

cat << EOF > /etc/kubernetes/etcd/kubeadmcfg.yaml
---
apiVersion: "kubeadm.k8s.io/v1beta3"
kind: InitConfiguration
nodeRegistration:
    name: ${NAME}
localAPIEndpoint:
    advertiseAddress: ${HOST}
---
apiVersion: "kubeadm.k8s.io/v1beta3"
kind: ClusterConfiguration
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
            initial-cluster: ${NAMES[0]}=https://${HOSTS[0]}:2380,${NAMES[1]}=https://${HOSTS[1]}:2380,${NAMES[2]}=https://${HOSTS[2]}:2380
            initial-cluster-state: new
            name: ${NAME}
            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380
EOF

kubeadm init phase certs etcd-server --config=/etc/kubernetes/etcd/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/etc/kubernetes/etcd/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/etc/kubernetes/etcd/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/etc/kubernetes/etcd/kubeadmcfg.yaml

mv /etc/kubernetes/pki/etcd/ca.key /tmp/ca.key
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r /etc/kubernetes/* root@${NAME}:/etc/kubernetes/
mv /tmp/ca.key /etc/kubernetes/pki/etcd/ca.key

if [ ${NAME} != ${NAMES[-1]} ]; then
    find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete
fi
done

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /etc/kubernetes/pki/etcd/ca.crt root@master-1:/etc/kubernetes/pki/etcd/ca.crt
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /etc/kubernetes/pki/apiserver-etcd-client* root@master-1:/etc/kubernetes/pki/


for i in "${!NAMES[@]}"; do
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${NAMES[$i]} "kubeadm init phase etcd local --config=/etc/kubernetes/etcd/kubeadmcfg.yaml"
done

