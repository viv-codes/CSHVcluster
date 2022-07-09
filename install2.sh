#!/bin/bash

curl -sSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_11/Release.key | apt-key add -
curl -sSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.22/Debian_11/Release.key | apt-key add -
curl -sSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_11/ /" > /etc/apt/sources.list.d/libcontainers.list
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.22/Debian_11/ /" > /etc/apt/sources.list.d/crio.list
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main"  > /etc/apt/sources.list.d/kubernetes.list
apt update -y && apt install -y cri-o cri-o-runc
systemctl enable --now crio
apt install -y "kubelet=1.24.2-00" "kubeadm=1.24.2-00" "kubectl=1.24.2-00"
apt-mark hold kubelet && apt-mark hold kubeadm && apt-mark hold kubectl
echo "Installation complete!"
