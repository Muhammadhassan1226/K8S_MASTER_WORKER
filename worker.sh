#! /bin/bash
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
apt update
apt full-upgrade -y
apt install -y apt-transport-https ca-certificates curl 
curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update
apt install -y apt-transport-https ca-certificates curl 
apt install -y kubelet kubeadm kubelet docker.io  

mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd.service
systemctl restart kubelet.service
systemctl start docker.service
systemctl enable kubelet.service
systemctl enable docker.service
