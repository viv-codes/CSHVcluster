# CSHVcluster
This repo contains info regarding CSH's Vcluster. You most likely won't have to care about the 'Installation' or 'Management' steps unless you're an RTP, if you're just looking to use the vcluster, skip to the usage section. 

Note: Most of the installation of the base k8s deployment came from [Galen's install guide](https://github.com/galenguyer/k8s), and has just been modified to fit the needs of this project. For an in-depth installation process, read that. If you want to precisely replciate the steps used to deploy the instance of k8s used in this project, follow Galen's guide for basic setup in PVE, then follow the directions below.

# Installation

### Services VM setup
Your services VM will be a vm with similar resources as the rest of your nodes, and will not have k8s installed on it in the same way. You can set it up with kubectl if you wish to use it to administer the rest of your cluster.
run `apt install haproxy -y` and copy `haproxy.cfg` to `/etc/haproxy/haproxy.cfg`. run `sudo systemctl restart haproxy` to load the new configuration

### Control and Worker nodes
This will be repeated once for each node, until your cluster meets the following requirements. You can just use templates like in Galen's guide, but due to the way my VMs were created (outside of my user scope bc this is a house resource), it wasn't an option. 

You will need:

* 3 Control nodes
* 2 Worker nodes 

Steps per node:
1. Install debian in a vm
2. `apt update -y && apt install -y vim curl`
3. make sure swap is disabled in fstab: `vim /etc/fstab`
4. is swap on? `cat /prox/meminfo | grep "Swap"` if so, reboot and check again to ensure it's off.
5. `curl https://raw.githubusercontent.com/viv-codes/CSHVcluster/main/install.sh > install.sh`
6. `chmod +x install.sh` and `./install.sh`
7. reboot
8. `./install2.sh`
9. `./kubeprep.sh`
This will start your initial control plane, it just runs `kubeadm init` with the proper args. Make note of the `kubeadm join` commands init provides. We'll be using those later. From here, I just followed Galen's guide for the per-node installation. I will copy it here with annotations altered to match this project.

run the following commands to get kubectl working easily on k8s-control-plane-01
```
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

install cluster networking. i'm using calico because flannel seems broken for some reason, idk
```
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### other control plane
kubeadm gave us two join commands. use the provided command to join the other two control plane nodes.

#### making control plane scheduleable
to allow pods to run on control plane nodes, run `kubectl taint nodes --all node-role.kubernetes.io/master-`

### compute
run the other join command to add our compute nodes to the cluster.

you can now run `kubectl get nodes` to see all the available nodes or `kubectl get pods -o wide --all-namespaces` to see all running pods

## kubectl on k8s-services
you'll probably want kubectl on your k8s-services vm. run the following commands to install it:
```
curl -sSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main"  > /etc/apt/sources.list.d/kubernetes.list
apt update -y && apt install "kubectl=1.22.4-00" -y
apt-mark hold kubectl
```

## [longhorn](https://github.com/longhorn/longhorn/)
longhorn is a really cute distributed storage driver. 

### installation
This second line is super important, cause if longhorn isn't designated as your default storage driver then vcluster will be very sad. 
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.2.2/deploy/longhorn.yaml
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
I don't care about the web dashboard bc the base cluster isn't going to be interacted with that much, most work will be done in vclusters. Your k8s deployment should now be healthy! When you run `kubectl get nodes` the response should look like this: 
```
vivi@k8s-ctrl01-nrh:~$ kubectl get nodes
NAME             STATUS   ROLES           AGE     VERSION
k8s-ctrl01-nrh   Ready    control-plane   2d14h   v1.24.2
k8s-ctrl02-nrh   Ready    control-plane   2d14h   v1.24.2
k8s-ctrl03-nrh   Ready    control-plane   2d14h   v1.24.2
k8s-wrkr01-nrh   Ready    <none>          2d14h   v1.24.2
k8s-wrkr02-nrh   Ready    <none>          2d14h   v1.24.2
```

## Vcluster setup
Ok so vcluster is really really cool and is what caused this whole project, and now you get to install it!! yay!! Vcluster docs are [here](https://www.vcluster.com/docs/getting-started/setup), if you run into any issues or just want to read them :3
### Download and install vcluster cli
```
curl -s -L "https://github.com/loft-sh/vcluster/releases/latest" | sed -nE 's!.*"([^"]*vcluster-linux-amd64)".*!https://github.com\1!p' | xargs -n 1 curl -L -o vcluster && chmod +x vcluster;
sudo mv vcluster /usr/local/bin;
```

To confirm that vcluster is installed properly, run `vcluster --version`

# Usage
Ok so this next part is really nice to have `tmux` running for, cause you're going to want to be multiplexing. If you're not familiar, the following commands are the bare minimum to do what you'll want to do here. More can be found [here](https://tmuxcheatsheet.com/).

| Command | Function |
|--- | --- |
| `$ tmux` | starts a new tmux session |
| `$ tmux ls` | lists open tmux session |
| `$ tmux a -t` | attaches to last session |
| `Ctrl`+`b` `d` | Detach from session |
| `Ctrl`+`b` `x` | Close pane |
| `Ctrl`+`b` `%` | New vertical pane |
| `Ctrl`+`b` `"` | New horizontal pane |
| `Ctrl`+`b` `o` | Toggle between open panes |
| `Ctrl`+`b` `z` | Toggle pane fullscreen zoom |


Create a vcluster!!! `vcluster create my-vcluster`. This starts the vcluster and moves you into the context of your new vcluster. To get started on interfacing with your new cluster, open a new pane in tmux by `Ctrl + b, "`. In that new window, you can now look around and explore your vcluster. Since vclusters function very similarly to a normal cluster, `kubectl` commands will work here!

First, run `kubectl config current-context` to ensure that you're in the proper context. On a fresh vcluster, the result should look like this:
```
root@k8s-ctrl01-nrh:~# kubectl get namespace
NAME              STATUS   AGE
default           Active   3h12m
kube-system       Active   3h12m
kube-public       Active   3h12m
kube-node-lease   Active   3h12m
```
Here are some sample commands that show you your k8s environment:
* Get namespaces in your cluster by running `kubectl get namespace`
* Get active pods in your cluster by running `kubectl get pods --all-namespaces`

Let's create a namespace and sample deployment, so that you can start learning k8s! 
```
kubectl create namespace demo-nginx
kubectl create deployment nginx-deployment -n demo-nginx --image=nginx
```
and
```
kubectl get pods -n demo-nginx
```
That's all there is to it! 
