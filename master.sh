#! /bin/bash

swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
apt update
apt full-upgrade -y
#---------------------
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
#---------------------
modprobe overlay
modprobe br_netfilter
#--------------------------
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
#--------------------
sysctl --system
#-------------
mkdir /etc/apt/keyrings
curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
#-----------
apt update
apt install -y apt-transport-https ca-certificates curl 
apt install -y kubelet kubeadm kubelet docker.io                #kubectl=1.25.9-00 (specify version if requird)
apt-mark hold kubelet kubeadm kubectl docker.io
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
#-----------
systemctl restart containerd.service
systemctl restart kubelet.service
systemctl start docker.service
systemctl enable kubelet.service
systemctl enable docker.service
#----------------------
kubeadm config images pull
kubeadm init --pod-network-cidr=192.168.0.0/16 #--kubernetes-version=1.25.9 --ignore-preflight-errors=all
#------------------
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
#------------
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/custom-resources.yaml
#-----------
watch -n5 kubectl get pods -A
