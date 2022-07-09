#!/bin/bash

echo cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory > /boot/cmdline.txt
apt update
apt upgrade -y
apt install -y rsync open-iscsi nfs-common gnupg2 curl apt-transport-https ca-certificates vim
systemctl enable --now iscsid
echo "br_netfilter" >> /etc/modules-load.d/kubernetes.conf
echo "overlay" >> /etc/modules-load.d/kubernetes.conf
modprobe br_netfilter
modprobe overlay
echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
