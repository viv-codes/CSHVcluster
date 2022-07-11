#!/usr/bin/env bash
# retrieve kube config files so we can use kubectl remotely

# exit if a command fails
set -o errexit
set -o pipefail
# exit if required variables aren't set
set -o nounset

mkdir -p ~/.kube/

if [ -n "$(dig +short k8s-ctrl01-nrh.csh.rit.edu)" ]; then
    echo 'running within cluster...'
    scp k8s-ctrl01-nrh:/etc/kubernetes/admin.conf ~/.kube/config
else
    echo 'running outside cluster...'
    scp root@129.21.49.96:/root/.kube/config ~/.kube/config
fi
