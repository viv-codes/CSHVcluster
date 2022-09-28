#!/bin/bash
<<com

This script automates the creation of users on freedom and the provisioning of namespaces and roles to users.

com

echo Welcome to CSH k8s user creation script
echo Enter username for new k8s user:
read uname
echo Username: $uname
homedir=$(find /users -maxdepth 2 -name $uname)
echo Is $homedir the correct homedir? [Ctrl+C if no]
read valid
cd $homedir
openssl genrsa -out $uname.key 2048
openssl req -new -key $uname.key -out $uname.csr -subj "/CN=$uname"
openssl x509 -req -in $uname.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out $uname.crt -days 500
mkdir .certs && mv $uname.crt $uname.key .certs

kubectl config set-credentials $uname --client-certificate=$homedir/.certs/$uname.crt --client-key=$homedir/.certs/$uname.key
kubectl config set-context $uname-context --cluster=kubernetes --user=$uname
mkdir .kube
echo "apiVersion: v1
clusters:
- cluster:
   certificate-authority-data: [[certificate]]
   server: https://k8s-services-nrh.csh.rit.edu:6443
  name: kubernetes
contexts:
- context:
   cluster: kubernetes
   user: $uname
  name: $uname-context
current-context: $uname-context
kind: Config
preferences: {}
users:
- name: $uname
  user:
   client-certificate: $homedir/.certs/$uname.crt
   client-key: $homedir/.certs/$uname.key" > .kube/config

mkdir .rbac
vcluster create $uname 

echo "kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $uname-statefulsets
  namespace: default
rules:
- apiGroups: [\"apps\"]
  resources: [\"statefulsets\", \"deployments\"]
  verbs: [\"get\", \"watch\", \"list\"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $uname-ns-statefulsets-view
  namespace: default
subjects:
- kind: User
  name: $uname
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $uname-statefulsets
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vcluster-$uname-full-access
  namespace: vcluster-$uname
rules:
- apiGroups: [\"\", \"extensions\", \"apps\"]
  resources: [\"*\"]
  verbs: [\"*\"]
- apiGroups: [\"batch\"]
  resources:
  - jobs
  - cronjobs
  verbs: [\"*\"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vcluster-$uname-vcluster-access
  namespace: vcluster-$uname
subjects:
- kind: User
  name: $uname
  namespace: vcluster-$uname
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: vcluster-$uname-full-access
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $uname-pvc
rules:
- apiGroups: [\"\"]
  resources:
  - nodes
  - persistentvolumes
  - namespaces
  verbs: [\"list\", \"watch\", \"edit\"]
- apiGroups: [\"storage.k8s.io\"]
  resources:
  - storageclasses
  verbs: [\"list\", \"watch\", \"edit\"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $uname-pvc-bind
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: $uname-pvc
subjects:
  - kind: User
    name: $uname" > .rbac/dev.yaml

kubectl apply -f .rbac/dev.yaml
kubectl config set-context kubernetes-admin@kubernetes
chown -R $uname $homedir/.rbac
chown -R $uname $homedir/.kube
chown -R $uname $homedir/.certs
echo User creation complete. User kubeconfig located in $homedir/.kube/config