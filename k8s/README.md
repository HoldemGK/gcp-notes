# Kubernetes tips & tricks

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
`kubectl run test --image=grafana/grafana --dry-run -o yaml`

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
  `kubectl -n my-namespace logs -f my-pod --timestamps`
  `kubectl -n my-namespace logs -f my-pod --tail=50`
  `kubectl -n my-namespace logs -f my-pod --all-containers`
  `kubectl -n my-namespace logs -f -l app=nginx`
  `kubectl -n my-namespace logs my-pod --previous`

  - Copy secret from one namespace to another
  `kubectl get secrets -o json --namespace namespace-old | \
  jq '.items[].metadata.namespace = "namespace-new"' | \
  kubectl create-f  -`

  - Create SSL cert
  `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=grafana.mysite.ru/O=MyOrganization"
kubectl -n myapp create secret tls selfsecret --key tls.key --cert tls.crt`

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

- Google Cloud-SDK container that will be run only on the second node pool with the protections enabled and not run as the root user
`kubectl run -it --rm gcloud --image=google/cloud-sdk:latest --restart=Never --overrides='{ "apiVersion": "v1", "spec": { "securityContext": { "runAsUser": 65534, "fsGroup": 65534 }, "nodeSelector": { "cloud.google.com/gke-nodepool": "second-pool" } } }' -- bash`
