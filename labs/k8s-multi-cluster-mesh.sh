#!/bin/bash
# Multi-cluster Mesh
export PROJECT="$(gcloud config list --format 'volume(core.project)')"
export PROJECT_ID="$(gcloud config list --format 'volume(core.project)')"
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
export C1_NAME="central"
export C1_ZONE="us-central1-b"
export C2_NAME="remote"
export C2_NAME_BASE="${C2_NAME}.k8s.local"
sudo apt install kubectx -y
sudo apt-get install google-cloud-sdk-kpt -y

# Check whether the remote cluster is ready
i=1; while [ $i ==1 ]; do echo "Checking cluster readiness...";
i=$(gsutil -q stat gs://$PROJECT_ID-kops-remote/config; echo $?);
sleep 5; done; echo "Cluster is ready!"

# Set up the Cloud Shell environment for command-line access to your clusters
export SHELL_IP=$(curl -s api.ipify.org)
gcloud compute firewall-rules create shell-to-remote --allow tcp --source-ranges $SHELL_IP
gsutil cp gs://$PROJECT_ID-kops-remote/config ~/.kube/config
kubectx remote=.
gcloud container clusters get-credentials central --zone $C1_ZONE
kubectx central=.

kubectx remote
kubectl get nodes

# Finish the remote cluster registration
export KSA=remote-admin-sa
printf "\n$(kubectl describe secret $KSA | sed -ne 's/^token:*//p')\n\n"

# Install and configure Anthos Service Mesh & Open Source Istio
curl -LO https://storage.googleapis.com/gke-release/asm/istio-1.6.8-asm.9-linux-amd64.tar.gz
tar xzf istio-1.6.8-asm.9-linux-amd64.tar.gz
cd istio-1.6.8-asm.9
export PATH=$PWD/bin:$PATH

# Create namespace and secret on central cluster
kubectx central
kubectl create ns istio-system
kubectl create secret generic cacerts -n istio-system \
--from-file=samples/certs/ca-cert.pem \
--from-file=samples/certs/ca-key.pem \
--from-file=samples/certs/root-cert.pem \
--from-file=samples/certs/cert-chain.pem

# Create namespace and secret on remote cluster
kubectx remote
kubectl create ns istio-system
kubectl create secret generic cacerts -n istio-system \
--from-file=samples/certs/ca-cert.pem \
--from-file=samples/certs/ca-key.pem \
--from-file=samples/certs/root-cert.pem \
--from-file=samples/certs/cert-chain.pem

# Configure the project to use Anthos Service Mesh
curl --request POST \
--header "Authorization: Bearer $(gcloud auth print-access-token)" --data '' \
https://meshconfig.googleapis.com/v1alpha1/projects/${PROJECT_ID}:initialize

# Install Anthos Service Mesh in the central GKE cluster, with tracing and multicluster enabled
kubectx central
# Note that we are downloading the version that will work with Citadel
# instead of Anthos Service Mesh CA, so that we can use the same Root CA
kpt pkg get \
https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm-citadel@release-1.6-asm asm

# Configure yaml files for install
kpt cfg set asm gcloud.container.cluster ${C1_NAME}
kpt cfg set asm gcloud.project.environProjectNumber ${PROJECT_NUMBER}
kpt cfg set asm gcloud.core.project ${PROJECT_ID}
kpt cfg set asm gcloud.compute.location ${C1_ZONE}

# Select the installation profile that assumes all clusters in one project
kpt cfg set asm anthos.servicemesh.profile asm-gcp

# Create a config file to enable Cloud Trace tracing
cat <<EOF > tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
  values:
    global:
      proxy:
        tracer: stackdriver
EOF

# Install Anthos Service Mesh with multicluster enabled
istioctl install \
  -f asm/cluster/istio-operator.yaml \
  -f tracing.yaml \
  -f manifests/examples/multicluster/values-istio-multicluster-gateways.yaml

# Enable the Anthos Service Mesh UI in Cloud Console
kubectl apply -f asm/canonical-service/controller.yaml

kubectl wait --for=condition=available --timeout=600s deployment \
--all -n istio-system

# Install Istio in the remote cluster

# Download istio
curl -sL https://istio.io/downloadIstioctl | ISTIO_VERSION=1.6.8 sh -

# Configure kubectl to work with remote cluster
kubectx remote

# Install Istio
~/.istioctl/bin/istioctl install \
  -f manifests/examples/multicluster/values-istio-multicluster-gateways.yaml

cat manifests/examples/multicluster/values-istio-multicluster-gateways.yaml

# Istio Control planes in the istio-system namespace
kubectx central
kubectl get namespaces

kubectx remote
kubectl get namespaces

kubectx central
kubectl get po -n istio-system | grep istiod

kubectx remote
kubectl get po -n istio-system | grep istiod

kubectx central
kubectl get crds -n istio-system | grep 'istio.io\|certmanager.k8s.io' | wc -l

kubectx remote
kubectl get crds -n istio-system | grep 'istio.io\|certmanager.k8s.io' | wc -l

kubectx central
istioctl version -o yaml | grep version

kubectx remote
~/.istioctl/bin/istioctl version -o yaml | grep version

# Configure DNS to locate services external to a cluster

# Configure kubectl to work with the central cluster
kubectx central

# Create and apply a ConfigMap config file
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"global": ["$(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})"]}
EOF

# Configure kubectl to work with the remote cluster
kubectx remote

# Create and apply a ConfigMap config file
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"global": ["$(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})"]}
EOF

kubectl --context central -n kube-system get configmap kube-dns -o json | jq '.data'

# CoreDNS setup
kubectl --context central -n istio-system get configmap coredns -o json | jq -r '.data.Corefile'

# Install Hipster Shop
cd $BASE_DIR
git clone https://github.com/GoogleCloudPlatform/training-data-analyst
cd training-data-analyst/courses/ahybrid/v1.0/AHYBRID081/hipster-shop

# Get Istio ingress gateway Ip addresses from both central and remote clusters
export GWIP_CENTRAL=$(kubectl --context central get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export GWIP_REMOTE=$(kubectl --context remote get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# change context to central cluster
kubectx central

# Prepare the service-entries yaml to add the remote cluster istio ingress
# gateway IP for all services running in the remote cluster
export pattern='.*- address:.*'
export replace="  - address: "$GWIP_REMOTE""
sed -r -i "s|$pattern|$replace|g" central/service-entries.yaml

# Create hipster2 namespace and enable istioInjection on the namespace
kubectl create namespace hipster2
kubectl label namespace hipster2 istio-injection=enabled

# Deploy part of hipster app on central cluster in the namespace hipster2
kubectl apply -n hipster2  -f central

# change context to remote cluster
kubectx remote

# Prepare the service-entries yaml to add the remote cluster istio ingress gateway IP
# for all services running in the remote cluster
export pattern='.*- address:.*'
export replace="  - address: "$GWIP_CENTRAL""
sed -r -i "s|$pattern|$replace|g" remote/service-entries.yaml

# Create hipster2 namespace and enable istioInjection on the namespace
kubectl create namespace hipster1
kubectl label namespace hipster1 istio-injection=enabled

# Deploy part of hipster app on remote cluster in the namespace hipster2
kubectl apply -n hipster1  -f remote

kubectl --context central -n hipster2 get all
kubectl --context remote -n hipster1 get all
kubectl --context central -n hipster2 get gateway -ojson | jq '.items[].spec'
kubectl --context central -n hipster2 get virtualservices -ojson | jq '.items[].spec'
kubectl --context central get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Review the deployments in each cluster
kubectl --context central -n hipster2 get deploy frontend -ojson | jq -r '[.spec.template.spec.containers[].env[]]'
kubectl --context remote -n hipster1 get deploy checkoutservice -ojson | jq -r '[.spec.template.spec.containers[].env[]]'

# Inspect the ServiceEntries in central
kubectl --context central -n hipster2 get serviceentries

# Inspect the ServiceEntries in remote
kubectl --context remote -n hipster1 get serviceentries

# Inspect one of the ServiceEntries for the endpoints field
kubectl --context central -n hipster2 get serviceentry checkoutservice-entry -ojson | jq '.spec.endpoints'

# Move services from remote to central
# Set kubectl to work with the central cluster
kubectx central

# Apply a config that creates the missing deployments on the central cluster
kubectl apply -n hipster2  -f hipster

# Delete the service entry resources that point to the remote cluster
kubectl delete -n hipster2 -f central/service-entries.yaml

# Set kubectl to work with the remote cluster
kubectx remote

# Delete the deployments on the remote cluster
kubectl delete -n hipster1  -f remote

kubectl --context central -n hipster2 get deploy frontend -ojson | jq -r '[.spec.template.spec.containers[].env[]]'
kubectl --context central -n hipster2 get deploy checkoutservice -ojson | jq -r '[.spec.template.spec.containers[].env[]]'
