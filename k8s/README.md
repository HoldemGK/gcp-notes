# Kubernetes tips & tricks

- Switch to the context Classic

`ssh -L 6443:localhost:6443 user@${CLUSTER_IP} #Create SSH tunnel

kubectl config set-cluster cluster_name \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://localhost:6443

kubectl config set-credentials admin
  --client-certificate=admin.pem \
  --client-key=admin-key.pem

kubectl config set-context context_name \
  --cluster=cluster_name \
  --user=admin

kubectl config use-context context_name`

- Switch to the context GKE
`gsutil cp gs://$DEVSHELL_PROJECT_ID-kops-onprem/config ~/.kube/onprem-config

export KUBECONFIG=~/.kube/config:~/.kube/onprem-config

kubectx onprem.k8s.local`

- Generate keys, and create secrets on your clusters
   generate an SSH keypair
`ssh-keygen -t rsa -b 4096 \
  -C "$GCLOUD_EMAIL" \
  -N '' \
  -f $HOME/.ssh/id_rsa.acm`

  Save the private key to a secret on each cluster
`kubectx gke
kubectl create secret generic git-creds \
    --namespace=config-management-system \
    --from-file=ssh=$HOME/.ssh/id_rsa.acm`

- Diagnosing an RBAC misconfiguration
`kubectl get pods -l app=pod-labeler
kubectl describe pod -l app=pod-labeler | tail -n 20
kubectl logs -l app=pod-labeler
kubectl get rolebinding pod-labeler -oyaml
kubectl get role pod-labeler -oyaml`

- Ensure your user account has the cluster-admin role
`kubectl create clusterrolebinding user-admin-binding \
   --clusterrole=cluster-admin \
   --user=$(gcloud config get-value account)`

- Create a Kubernetes service account called Tiller
`kubectl create serviceaccount tiller --namespace kube-system`

- Grant the Tiller service account the cluster-admin role
`kubectl create clusterrolebinding tiller-admin-binding \
   --clusterrole=cluster-admin \
   --serviceaccount=kube-system:tiller`

- Allow autocomplete
`source <(kubectl completion bash)`

- Problems pods
`kubectl get pods -A --field-selector=status.phase!=Running | grep -v Complete`

- List of nodes with memory
`kubectl get no -o json | \
  jq -r '.items | sort_by(.status.capacity.memory)[]|[.metadata.name,.status.capacity.memory]| @tsv'`

- List of nodes and pods include
`kubectl get po -o json --all-namespaces | \
  jq '.items | group_by(.spec.nodeName) | map({"nodeName": .[0].spec.nodeName, "count": length}) | sort_by(.count)'`

- List of problem nodes
`ns=my-namespace
pod_template=my-pod
kubectl get node | grep -v \"$(kubectl -n ${ns} get pod --all-namespaces -o wide | fgrep ${pod_template} | awk '{print $8}' | xargs -n 1 echo -n "\|" | sed 's/[[:space:]]*//g')\"`

- Pods consumption of memory and CPU
`# cpu
kubectl top pods -A | sort --reverse --key 3 --numeric
# memory
kubectl top pods -A | sort --reverse --key 4 --numeric`

- Sort pods by restarts
`kubectl get pods --sort-by=.status.containerStatuses[0].restartCount`

- Get pods from service selector
`kubectl -n jaeger get svc -o wide`

- Limits of pods
`kubectl get pods -n my-namespace -o=custom-columns='NAME:spec.containers[*].name,MEMREQ:spec.containers[*].resources.requests.memory,MEMLIM:spec.containers[*].resources.limits.memory,CPUREQ:spec.containers[*].resources.requests.cpu,CPULIM:spec.containers[*].resources.limits.cpu'`

- Get manifest before start
`kubectl run test --image=grafana/grafana --dry-run=client -o yaml`

- Run interactive shell to a temporary Pod
`kubectl run redis-test --rm --tty -i --restart='Never' \
    --env REDIS_PW=$REDIS_PW \
    --env REDIS_IP=$REDIS_IP \
    --image docker.io/bitnami/redis:4.0.12 -- bash`

- Resource description
`kubectl explain hpa`

- Get PrivateIP of node
`kubectl get nodes -o json | \
  jq -r '.items[].status.addresses[]? | select (.type == "InternalIP") | .address' | \
  paste -sd "\n" -`

  - Get services and nodePort
  `kubectl get --all-namespaces svc -o json | \
  jq -r '.items[] | [.metadata.name,([.spec.ports[].nodePort | tostring ] | join("|"))]| @tsv'`

  - Get subnets of pods
  `kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}' | tr " " "\n"`

  - Logs of pods
  `kubectl -n my-namespace logs my-pod --timestamps`
  `kubectl -n my-namespace logs my-pod --tail=50`
  `kubectl -n my-namespace logs my-pod --all-containers`
  `kubectl -n my-namespace logs -l app=nginx`
  `kubectl -n my-namespace logs my-pod --previous`

  - Copy secret from one namespace to another
  `kubectl get secrets -o json --namespace namespace-old | \
  jq '.items[].metadata.namespace = "namespace-new"' | \
  kubectl create -f  -`

  - Create SSL cert
  `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=grafana.mysite.ru/O=MyOrganization"
kubectl -n myapp create secret tls selfsecret --key tls.key --cert tls.crt`

- Copy file to pod
`kubectl cp ~/test.html $my_nginx_pod:/usr/share/nginx/html/test.html`

- Deploy a pod that mounts the host filesystem
`cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: hostpath
spec:
  containers:
  - name: hostpath
    image: google/cloud-sdk:latest
    command: ["/bin/bash"]
    args: ["-c", "tail -f /dev/null"]
    volumeMounts:
    - mountPath: /rootfs
      name: rootfs
  volumes:
  - name: rootfs
    hostPath:
      path: /
EOF`

`kubectl exec -it hostpath -- bash`

- To run the Microsoft SQL tools container
`kubectl run sqltools --image=microsoft/mssql-tools -ti --restart=Never --rm=true -- /bin/bash`

- Google Cloud-SDK container that will be run only on the second node pool with the protections enabled and not run as the root user
`kubectl run -it --rm gcloud --image=google/cloud-sdk:latest --restart=Never --overrides='{ "apiVersion": "v1", "spec": { "securityContext": { "runAsUser": 65534, "fsGroup": 65534 }, "nodeSelector": { "cloud.google.com/gke-nodepool": "second-pool" } } }' -- bash`

- Change Namespace
`# Add the following to .zshrc/.bashrc...etc
# Allows setting default namespace while working with kubectl #

alias k='kubectl'
alias ksn='_f(){k get namespace $1 > /dev/null; if [ $? -eq 1 ]; then return $?; fi;  k config set-context $(k config current-context) --namespace=$1; echo "Namespace: $1"};_f'

#Usage:
#➜  ~ ksn dev1                                                       (dev-context/dev1)
#     Context "dev-context" modified.
#     Namespace: dev1

- Aliases
`alias k='kubectl '
alias kcc='kubectl config current-context'
alias kdp='kubectl delete po'
alias kgc='kubectl config get-contexts'
alias kge='kubectl get events --sort-by='\''{.lastTimestamp}'\'
alias kgp='kubectl get po'
alias kl='kubectl logs '
alias kpf='kubectl port-forward'
alias ksc='kubectl config use-context'`
