#!/bin/bash
# Deploying Memcached on Kubernetes Engine

export ZONE=us-central1-f
gcloud container clusters create demo-cluster --num-nodes 3 --zone $ZONE
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
helm install mycache stable/memcached --set replicaCount=3
kubectl get po
kubectl get svc mycache-memcached -o jsonpath="{.spec.clusterIP}" ;
echo
kubectl get endpoints mycache-memcached
kubectl run -it --rm alpine --image=alpine:3.6 --restart=Never nslookup mycache-memcached.default.svc.cluster.local
kubectl run -it --rm python --image=python:3.6-alpine --restart=Never python
import socket
print(socket.gethostbyname_ex('mycache-memcached.default.svc.cluster.local'))
exit()

# Test the deployment by opening a telnet session with one of the running Memcached servers on port 11211
kubectl run -it --rm alpine --image=alpine:3.6 --restart=Never telnet mycache-memcached-0.mycache-memcached.default.svc.cluster.local 11211
set mykey 0 0 5
hello
get mykey
quit

# Deploy Mcrouter
helm delete mycache
helm install mycache stable/mcrouter --set memcached.replicaCount=3
kubectl get po
# Test this setup by connecting to one of the proxy pods
MCROUTER_POD_IP=$(kubectl get pods -l app=mycache-mcrouter -o jsonpath="{.items[0].status.podIP}")
kubectl run -it --rm alpine --image=alpine:3.6 --restart=Never telnet $MCROUTER_POD_IP 5000
set anotherkey 0 0 15
MCrouter is fun
get anotherkey
quit

# Expose the Kubernetes Node Name as an Environment Variable
cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-application-py
spec:
  replicas: 5
  selector:
    matchLabels:
      app: sample-application-py
  template:
    metadata:
      labels:
        app: sample-application-py
    spec:
      containers:
        - name: python
          image: python:3.6-alpine
          command: [ "sh", "-c"]
          args:
          - while true; do sleep 10; done;
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
EOF
kubectl get pods
POD=$(kubectl get pods -l app=sample-application-py -o jsonpath="{.items[0].metadata.name}")
