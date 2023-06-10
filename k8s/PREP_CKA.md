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

## Deployment

- Rollout
```bash
k rollout status deploy/my-app
k rollout history deploy/my-app
k rollout undo deploy/my-app
```

## Namespace

```bash
k create ns dev
k config set-context $(k config current-context) --namespace=dev
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

## Encryption

- Activate

https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

```bash
cat /etc/kubernetes/enc/enc.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: # head -c 32 /dev/random | base64
      - identity: {}
```
add string to the /etc/kubernetes/manifests/kube-apiserver.yaml
```bash
--encryption-provider-config=/etc/kubernetes/enc/enc.yaml

volumeMounts:
- name: enc
  mountPath: /etc/kubernetes/enc
  readonly: true
volumes:
- name: enc
  hostPath: /etc/kubernetes/enc
  type: DirectoryOrCreate
```

Updating existing secrets:
```bash
k get secrets -A -o json | k replace -f -
```

## Working with ETCDCTL

etcdctl is a command line client for etcd.

 

In all our Kubernetes Hands-on labs, the ETCD key-value database is deployed as a static pod on the master. The version used is v3.

To make use of etcdctl for tasks such as back up and restore, make sure that you set the ETCDCTL_API to 3.

You can do this by exporting the variable ETCDCTL_API prior to using the etcdctl client. This can be done as follows:

export ETCDCTL_API=3

On the Master Node:
```bash
export ETCDCTL_API=3
etcdctl version

# Backup
k logs etcd-controlplane -n kube-system
k describe pod etcd-controlplane -n kube-system
etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /opt/snapshot-pre-boot.db

# Restore 
etcdctl --data-dir=/var/lib/etcd-from-backup snapshot restore /opt/snapshot-pre-boot.db
# Update /etc/kubernetes/manifests/etcd.yaml
# volumes:
#   - hostPath:
#       path: /var/lib/etcd-from-backup
#       type: DirectoryOrCreate
#     name: etcd-data
watch "crictl ps | grep etcd"
```

To see all the options for a specific sub-command, make use of the -h or –help flag.


For example, if you want to take a snapshot of etcd, use:

etcdctl snapshot save -h and keep a note of the mandatory global options.

Since our ETCD database is TLS-Enabled, the following options are mandatory:

–cacert                verify certificates of TLS-enabled secure servers using this CA bundle

–cert                    identify secure client using this TLS certificate file

–endpoints=[127.0.0.1:2379] This is the default as ETCD is running on master node and exposed on localhost 2379.

–key                  identify secure client using this TLS key file

## Security

- Generate certs
```bash
# Certificate Auth
openssl genrsa -out ca.key 2048 # Generate
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr # Cert Signing request
openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt # Sign Cert

# Admin User Client-cert
openssl genrsa -out admin.key 2048 # Generate
openssl req -new -key admin.key -subj "/CN=kube-admin/O=system:masters" -out admin.csr # Cert Signing request
openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -out admin.crt # Sign Cert

# How to use
curl https://kube-apiserver:6443/api/v1/pods --key admin.key --cert admin.crt --cacert ca.crt

cat kube-config.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: ca.crt
    server: https://kube-apiserver:6443
  name: kubernetes
users:
- name: kubernetes-admin
  user:
    client-certificate: admin.crt
    client-key: admin.key

# Kube API Server Cert Create
openssl genrsa -out apiserver.key 2048 # Generate
openssl req -new -key apiserver.key -subj "/CN=kube-apiserver" -out apiserver.csr -config openssl.cnf # Cert Signing request
openssl x509 -req -in apiserver.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out apiserver.crt -extensions v3_req -extfile openssl.cnf -days 1000 # Sign Cert
cat openssl.cnf
[req]
req_exstensnions = v3_req
destinguished_name = req_destinguished_name
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation,
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = 10.96.0.1
IP.2 = 172.17.0.87
```

- Network Policies
```bash
cat net_pol.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          name: api-pod
    - ipBlock:
        cidr: 192.168.0.0/24  # allow connection from backup server outside cluster
    ports:
    - protocol: TCP
      port: 3306
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

# Network Comands
ip link
ip addr show type bridge
ip addr add 192.168.1.10/24 dev eth0
ip route add 192.168.1.10/24 via 192.168.2.1
cat /proc/sys/net/ipv4/ip_forward
arp
route
netstat -nplt
netstat -anp | grep etcd | grep 2379 | wc -l  # Count connections

# Cert command check expiration
openssl x509 -in /var/lib/kubelet/worker-1.crt -text

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