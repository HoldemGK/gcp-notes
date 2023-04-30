# Preparation to CKA

```bash
k get pods -n kube-system
```

- Kube API Server
```bash
# Installing wget
wget https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-apiserver

# View api-server options - kubeadm
cat /etc/kubernetes/manifests/kube-apiserver.yaml

# View api-server options - none kubeadm
cat /etc/systemd/system/kube-apiserver.service
ps -aux | grep kube-apiserver
```

- Kube Controller Manager
```bash
# Installing wget
wget https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-controller-manager

# View api-server options - kubeadm
cat /etc/kubernetes/manifests/kube-controller-manager.yaml

# View api-server options - none kubeadm
cat /etc/systemd/system/kube-controller-manager.service
ps -aux | grep kube-controller-manager
```