export MY_REGION=us-central1
export MY_ZONE=us-central1-a
export CLUSTER_NAME=httploadbalancer
gcloud config set project $DEVSHELL_PROJECT_ID
gcloud config set compute/region $MY_REGION
gcloud config set compute/zone $MY_ZONE
gcloud config list
#Create a Kubernetes cluster for network load balancing
gcloud container clusters create networklb --num-nodes 3
#Deploy nginx in Kubernetes
kubectl run nginx --image=nginx --replicas=3
kubectl get pods -owide
kubectl expose deployment nginx --port=80 --target-port=80 --type=LoadBalancer
kubectl get service nginx
#Undeploy nginx
kubectl delete service nginx
kubectl delete deployment nginx
gcloud container clusters delete networklb
#Create the Kubernetes cluster for HTTP load balancing
gcloud container clusters create $CLUSTER_NAME --zone $MY_ZONE
#Create and expose the services
kubectl run nginx --image=nginx --port=80
kubectl expose deployment nginx --target-port=80 --type=NodePort
#Create an ingress object
nano basic-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: basic-ingress
spec:
  backend:
    serviceName: nginx
    servicePort: 80

kubectl create -f basic-ingress.yaml
kubectl get ingress basic-ingress --watch
kubectl describe ingress basic-ingress
kubectl get ingress basic-ingress
#Shut down the cluster
kubectl delete -f basic-ingress.yaml
kubectl delete deployment nginx
gcloud container clusters delete $CLUSTER_NAME
