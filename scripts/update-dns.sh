#!/bin/bash

# Point to Google's DNS server
sed -i -e 's/#DNS=/DNS=172.16.1.2/' /etc/systemd/resolved.conf

service systemd-resolved restart