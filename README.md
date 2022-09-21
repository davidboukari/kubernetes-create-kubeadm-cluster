# kubernetes-create-kubeadm-cluster

# On the master
```
chmod +x install-master.sh
./install-master.sh master1 1.23.0-00
```

* If you need a kubeadm token to create and print join command
``` 
kubeadm token create --print-join-command
kubeadm join 192.168.1.147:6443 --token xscqpy.cka6qomszzn4wik9 --discovery-token-ca-cert-hash sha256:acd6323967d2f1f53e9dcb54b3c329cc4dff02c6d5dfd4ee67d5014f957607f2
```


# On the node
```
chmod +x install-node.sh
install-node.sh node1 1.23.0-00

# Execute the command join from master
Ex: kubeadm join 192.168.1.147:6443 --token gvlpbd.r3d9pt3nqhzzqizi \
> --discovery-token-ca-cert-hash sha256:acd6323967d2f1f53e9dcb....
```










