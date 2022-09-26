#!/bin/bash

apt-get update
apt-get install -y nginx

mkdir -p /etc/nginx/tcpconf.d

cat << EOF | sudo tee -a /etc/nginx/nginx.conf
include /etc/nginx/tcpconf.d/*.conf;
EOF

cat << EOF | sudo tee /etc/nginx/tcpconf.d/default.conf
stream {
    upstream kube-apiserver {
        server 192.168.203.11:6443;
        server 192.168.203.12:6443;
    }
    server {
    listen 6443;
    proxy_pass kube-apiserver;
    }
}
EOF

sed -i '/sites-enabled/d'  /etc/nginx/nginx.conf

systemctl restart nginx