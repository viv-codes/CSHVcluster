#!/bin/bash
kubeadm init --apiserver-advertise-address=0.0.0.0 --apiserver-cert-extra-sans="$(curl -sSL ifconfig.me),k8s.csh.rit.edu" --kubernetes-version=1.24.2 --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=k8s-serices.csh.rit.edu:6443 --upload-certs
