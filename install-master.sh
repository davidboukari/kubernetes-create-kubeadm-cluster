#!/bin/bash

function usage(){
  echo "$0 <HOSTNAME> <CLUSTER_VERSION>"
  echo "ex: $0 master1 1.23.0-00"
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


swapoff -a

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

# Start the cluster
ip=$(hostname -I|awk '{print $1}')
sudo kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address=$ip

sudo mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config


# Install coredns
#kubectl -n kube-system get po
#NAME                                 READY   STATUS    RESTARTS   AGE
#coredns-64897985d-b8m2q              0/1     Pending   0          8m10s
#coredns-64897985d-lsv7b              0/1     Pending   0          8m10s
#etcd-ubuntu2004                      1/1     Running   2          8m25s
#kube-apiserver-ubuntu2004            1/1     Running   2          8m18s
#kube-controller-manager-ubuntu2004   1/1     Running   2          8m23s
#kube-proxy-d6p22                     1/1     Running   0          8m10s
#kube-scheduler-ubuntu2004            1/1     Running   2          8m26s

# Install network plugin
kubectl get pods -n kube-system -o wide|grep -i weave
   kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
kubectl get pods -n kube-system -o wide|grep -i weave

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh



#helm repo add coredns https://coredns.github.io/helm
#helm --namespace=kube-system install coredns coredns/coredns

