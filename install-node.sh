#!/bin/bash

function usage(){
  echo "$0 <HOSTNAME> <CLUSTER_VERSION>"
  echo "ex: $0 node1 1.23.0-00"
}


if [  "$#" -lt 2 ];then
  usage	
  exit 10
fi

# Need Root Access
if [ "`id -u`" != "0" ];then
  sudo $0 $@
fi


HOSTNAME=$1
echo $HOSTNAME > /etc/hostname
hostname -b $HOSTNAME 

# For the last version set empty '' else do not forget =
#VERSION=''
#VERSION='=1.23.0-00'
VERSION="=$2"

sysctl net.ipv4.conf.lo.forwarding=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf


# Completion
apt-get install -y  bash-completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
#echo 'alias k=kubectl' >>~/.bashrc
#echo 'complete -o default -F __start_kubectl k' >>~/.bashrc


# disable swap
swapoff -a
sed -i 's!^/swap!#/swap!g' /etc/fstab

# Install docker
apt-get install -y docker

# Update the apt package index and install packages needed to use the Kubernetes apt repository:
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Download the Google Cloud public signing key:
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# Add the Kubernetes apt repository:
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update
#sudo apt-get install kubelet${VERSION} kubeadm${VERSION} kubectl${VERSION}
#sudo apt-get upgrade kubelet${VERSION} kubeadm${VERSION} kubectl${VERSION}
sudo apt-get install -y kubelet${VERSION} kubeadm${VERSION} kubectl${VERSION}
sudo apt-mark hold kubelet kubeadm kubectl


# Reinstall docker.io
apt-get install -y docker.io

# Fix Docker driver for kubelet issues
cat<<EOF>>/etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF


sudo systemctl enable --now docker
sudo systemctl restart docker

sudo systemctl enable --now kubelet
sudo systemctl restart kubelet

echo "Now execute the command done by the control plain like: kubeadm join 192.168.1.147:6443 --token mr3de5.gmpt79yds71yfqf0 --discovery-token-ca-cert-hash sha256:5b1cdddc1f14317a9917f074ac69afa85d2cffcba00886f60d7790fe405b4dfa"



