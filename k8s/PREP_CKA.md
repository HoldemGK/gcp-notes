# Preparation to CKA

```bash
k get pods -n kube-system
```

- Kube API Server
```bash
# Installing from binary
wget https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-apiserver

# View api-server options - kubeadm
cat /etc/kubernetes/manifests/kube-apiserver.yaml

# View api-server options - none kubeadm
cat /etc/systemd/system/kube-apiserver.service
ps -aux | grep kube-apiserver
```

- Kube Controller Manager
```bash
# Installing wfrom binary
wget https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-controller-manager

# View api-server options - kubeadm
cat /etc/kubernetes/manifests/kube-controller-manager.yaml

# View api-server options - none kubeadm
cat /etc/systemd/system/kube-controller-manager.service
ps -aux | grep kube-controller-manager
```

- Kube Proxy
```bash
# Installing wfrom binary
wget https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-proxy

# View api-server options - kubeadm
k get daemonset -n kube-system
```

- Working with pods
```bash
k run nginx --image nginx

# YAML example
cat pod-definition.yaml
apiVersion:
kind:
metadata:

spec:
```

## Service

Node port range = 30000 - 32767

## Namespace

```bash
k create ns dev
k config set-context $(k config current-context) -n dev
k get pod --all-namespaces
cat quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: dev
spec:
  hard:
    pods: "10"
    requests.cpu: "4"
    requests.memory: 5Gi
    limits.cpu: "10"
    limits.memory: 10Gi
```

## Tips

https://kubernetes.io/docs/reference/kubectl/conventions/

```bash
#Create an NGINX Pod

kubectl run nginx --image=nginx

#Generate POD Manifest YAML file (-o yaml). Don’t create it(–dry-run)

kubectl run nginx --image=nginx --dry-run=client -o yaml

#Create a deployment

kubectl create deployment --image=nginx nginx

#Generate Deployment YAML file (-o yaml). Don’t create it(–dry-run)

kubectl create deployment --image=nginx nginx --dry-run=client -o yaml

#Generate Deployment YAML file (-o yaml). Don’t create it(–dry-run) and save it to a file.

kubectl create deployment --image=nginx nginx --dry-run=client -o yaml > nginx-deployment.yaml

#Service

# This will automatically use the pod’s labels as selectors
kubectl expose pod redis --port=6379 --name redis-service --dry-run=client -o yaml

# This will not use the pods labels as selectors, instead it will assume selectors as app=redis
kubectl create service clusterip redis --tcp=6379:6379 --dry-run=client -o yaml

# Create a Service named nginx of type NodePort to expose pod nginx’s port 80 on port 30080 on the nodes
kubectl expose pod nginx --type=NodePort --port=80 --name=nginx-service --dry-run=client -o yaml

# This will not use the pods labels as selectors
kubectl create service nodeport nginx --tcp=80:80 --node-port=30080 --dry-run=client -o yaml

```
- Default Resource Requirements and Limits
```bash
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
spec:
  limits:
  - default:
      memory: 512Mi  # cpu: 1
    defaultRequest:
      memory: 256Mi  # cpu: 0.5
    type: Container
```