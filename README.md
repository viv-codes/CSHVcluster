# CSHVcluster

## Installation
1. Install debian in a vm
2. `apt update -y && apt install -y vim curl`
3. make sure swap is disabled in fstab: `vim /etc/fstab`
4. is swap on? `cat /prox/meminfo | grep "Swap"` if so, reboot and check again to ensure it's off.
5. `curl https://raw.githubusercontent.com/viv-codes/CSHVcluster/main/install.sh > install.sh`
6. `chmod +x install.sh` and `./install.sh`
7. reboot
8. `./install2.sh`
\\ And that's it! Nodes are now ready to be brought up. 
1. ssh into k8s-ctrl01-nrh and run the following:
```
kubeadm init --apiserver-advertise-address=0.0.0.0 --apiserver-cert-extra-sans="$(curl -sSL ifconfig.me),k8s.csh.rit.edu" --kubernetes-version=1.24.2 --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=k8s-serices.csh.rit.edu:6443 --upload-certs
```
