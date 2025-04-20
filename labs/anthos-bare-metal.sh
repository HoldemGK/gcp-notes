# configure environment variables
export PROJECT=$(gcloud config get-value project)
export REGION="europe-central2"
export ZONE="${REGION}-c"
export WS_MACHINE_TYPE=e2-standard-4
export CLUSTER_MACHINE_TYPE=e2-standard-4
export VM_PREFIX=abm
export VM_WS=$VM_PREFIX-ws
export VM_A_CP1=$VM_PREFIX-admin-cp1
export VM_U_CP1=$VM_PREFIX-user-cp1
export VM_U_W1=$VM_PREFIX-user-w1
export IMG_FAM=ubuntu-2004-lts
export IMG_PRJ=ubuntu-os-cloud
export ANS_NET=anthos-network
export SCOPES=cloud-platform

# creating arrays
declare -a VMs=("$VM_WS" "$VM_A_CP1" "$VM_U_CP1" "$VM_U_W1")

declare -a ADMIN_CP_VMs=("$VM_A_CP1")
declare -a USER_CP_VMs=("$VM_U_CP1")
declare -a USER_WORKER_VMs=("$VM_U_W1")
declare -a LB_VMs=("$VM_A_CP1" "$VM_U_CP1")

declare -a IPs=()

# Building the GCE VMs that act as bare metal servers
# Admin Workstation VM
gcloud compute instances create $VM_WS --image-family=$IMG_FAM --image-project=$IMG_PRJ --zone=${ZONE} \
  --boot-disk-size 128G --boot-disk-type pd-ssd --can-ip-forward --network $ANS_NET --subnet=${REGION}-subnet \
  --scopes $SCOPES --machine-type $WS_MACHINE_TYPE --metadata=os-login=FALSE --verbosity=error

IP=$(gcloud compute instances describe $VM_WS --zone ${ZONE} --format='get(networkInterfaces[0].networkIP)')
IPs+=("$IP")

# Creating the VMs used as cluster servers
for vm in "${VMs[@]:1}"
do
  gcloud compute instances create $vm --image-family=$IMG_FAM --image-project=$IMG_PRJ --zone=${ZONE} \
    --boot-disk-size 128G --boot-disk-type pd-standard --can-ip-forward --network $ANS_NET --subnet=${REGION}-subnet \
    --scopes $SCOPES --machine-type $CLUSTER_MACHINE_TYPE --metadata=os-login=FALSE --verbosity=error

  IP=$(gcloud compute instances describe $vm --zone ${ZONE} --format='get(networkInterfaces[0].networkIP)')
  IPs+=("$IP")
done

# Assigning appropriate network tags
for vm in "${ADMIN_CP_VMs[@]}"
do
  gcloud compute instances add-tags $vm --zone ${ZONE} --tags="cp,admin"
done

for vm in "${USER_CP_VMs[@]}"
do
  gcloud compute instances add-tags $vm --zone ${ZONE} --tags="cp,user"
done

for vm in "${USER_WORKER_VMs[@]}"
 do
     gcloud compute instances add-tags $vm --zone ${ZONE} --tags="worker,user"
 done

 for vm in "${LB_VMs[@]}"
 do
     gcloud compute instances add-tags $vm --zone ${ZONE} --tags="lb"
 done

 for vm in "${VMs[@]}"
 do
     gcloud compute instances add-tags $vm --zone ${ZONE} --tags="vxlan"
 done

 # Configuring the server OS as required for bare metal Anthos
 for vm in "${VMs[@]}"
 do
   echo "Disabling UFW on $vm"
   gcloud compute ssh root@$vm --zone ${ZONE} --tunnel-through-iap << EOF
        sudo ufw disable
EOF
done

# Configuring each VM to implement vxlan functionality; each VM gets an IP address in the 10.200.0.x range
i=2
for vm in "${VMs[@]}"
do
  gcloud compute ssh root@$vm --zone ${ZONE} --tunnel-through-iap << EOF
    apt-get -qq update > /dev/null
    apt-get -qq install -y jq > /dev/null
    set -x

    # creating new vxlan config
    ip link vxlan0 type vxlan id 42 dev ens4 dstport 4789
    current_ip=\$(ip --json a show dev ens4 | jq '.[0].addr_info[0].local' -r)
    echo "VM IP address is: \$current_ip"
    for ip in ${IPs[@]}; do
      if [ "\$ip" != "\$current_ip" ]; then
        bridge fdb append to 00:00:00:00:00:00 dst \$ip dev vxlan0
      fi
    done
    ip addr add 10.200.0.$i/24 dev vxlan0
    ip link set up dev vxlan0
EOF
  i=$((i+1))
done

# Checking the vxlan IPs that have been associated with each of the VM
i=2
for vm in "${VMs[@]}"
do
  echo $vm;
  gcloud compute ssh root@$vm --zone ${ZONE} --tunnel-through-iap --command="hostname -I"
  i=$((i+1))
done

# Creating the firewall rules that allow traffic to the control plane servers
gcloud compute firewall-rules create abm-allow-cp --network=$ANS_NET \
  --allow="UDP:6081,TCP:22,TCP:6444,TCP:2379-2380,TCP:10250-10252,TCP:4240" \
  --source-ranges="10.0.0.0/8" --target-tags="cp"

# Creating the firewall rules that allow inbound traffic to the worker nodes
gcloud compute firewall-rules create abm-allow-worker --network=$ANS_NET \
  --allow="UDP:6081,TCP:22,TCP:10250,TCP:30000-32767,TCP:4240" \
  --source-ranges="10.0.0.0/8" --target-tags="worker"

# Creating the firewall rules that allow inbound traffic to the load balancer nodes
gcloud compute firewall-rules create abm-allow-lb --network=$ANS_NET \
  --allow="UDP:6081,TCP:22,TCP:443,TCP:7946,UDP:7946,TCP:4240" \
  --source-ranges="10.0.0.0/8" --target-tags="lb"

gcloud compute firewall-rules create allow-gfe-to-lb --network=$ANS_NET \
  --allow="TCP:443" --target-tags="lb" \
  --source-ranges="10.0.0.0/8,130.211.0.0/22,35.191.0.0/16"

# Creating the firewall rules that allow multi-cluster traffic
gcloud compute firewall-rules create abm-allow-multi --network=$ANS_NET \
  --allow="TCP:22,TCP:443" --source-tags="admin" --target-tags="user"


# Set up the admin workstation
eval `ssh-agent`

# add your identity
ssh-add ~/.ssh/google_compute_engine

# ssh into the admin workstation with authentication forwarding
gcloud compute ssh --ssh-flag="-A" root@$VM_WS \
    --zone ${ZONE} \
    --tunnel-through-iap

# restarting shell
exec -l $SHELL

# Creating keys for a service account with the same permissions as the lab user
gcloud iam service-accounts keys create installer.json \
  --iam-account=${PROJECT}@${PROJECT}.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS=~/installer.json

gcloud components install kubectl
kubectl config view
mkdir baremetal && cd baremetal

gsutil cp gs://anthos-baremetal-release/bmctl/1.16.0/linux-amd64/bmctl .
chmod a+x bmctl
mv bmctl /usr/local/sbin
bmctl version

cd ~
echo "Installing docker"
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
docker version

# Configuring servers to allow SSH from admin workstation
ssh-keygen -t rsa

VM_PREFIX=abm
VM_WS=$VM_PREFIX-ws
VM_A_CP1=$VM_PREFIX-admin-cp1
VM_U_CP1=$VM_PREFIX-user-cp1
VM_U_W1=$VM_PREFIX-user-w1

declare -a VMs=("$VM_WS" "$VM_A_CP1" "$VM_U_CP1" "$VM_U_W1")

for vm in "${VMs[@]:1}"
do
    ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub root@$vm
done

git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Creating admin cluster
 # configure environment variables
export SSH_PRIVATE_KEY=/root/.ssh/id_rsa
export LB_CONTROLL_PLANE_NODE=10.200.0.3
export LB_CONTROLL_PLANE_VIP=10.200.0.98

 # create additional arrays of the server names
declare -a ADMIN_CP_VMs=("$VM_A_CP1")
declare -a USER_CP_VMs=("$VM_U_CP1")
declare -a USER_WORKER_VMs=("$VM_U_W1")
declare -a LB_VMs=("$VM_A_CP1" "$VM_U_CP1")

cd ~/baremetal
bmctl create config -c abm-admin-cluster   --enable-apis --create-service-accounts --project-id=$PROJECT
ls bmctl-workspace/.sa-keys/

# Editing the configuration file
cat bmctl-workspace/abm-admin-cluster/abm-admin-cluster.yaml
sed -r -i "s|sshPrivateKeyPath: <path to SSH private key, used for node access>|sshPrivateKeyPath: $(echo $SSH_PRIVATE_KEY)|g" bmctl-workspace/abm-admin-cluster/abm-admin-cluster.yaml
sed -r -i "s|type: hybrid|type: admin|g" bmctl-workspace/abm-admin-cluster/abm-admin-cluster.yaml
sed -r -i "s|- address: <Machine 1 IP>|- address: $(echo $LB_CONTROLL_PLANE_NODE)|g" bmctl-workspace/abm-admin-cluster/abm-admin-cluster.yaml
sed -r -i "s|controlPlaneVIP: 10.0.0.8|controlPlaneVIP: $(echo $LB_CONTROLL_PLANE_VIP)|g" bmctl-workspace/abm-admin-cluster/abm-admin-cluster.yaml

head -n -11 bmctl-workspace/abm-admin-cluster/abm-admin-cluster.yaml > temp_file && mv temp_file bmctl-workspace/abm-admin-cluster/abm-admin-cluster.yaml
cat bmctl-workspace/abm-admin-cluster/abm-admin-cluster.yaml

bmctl create cluster -c abm-admin-cluster

# Accessing to the Kind cluster exports the logs
export LATEST_ADMIN_FOLDER=$(ls -d bmctl-workspace/abm-admin-cluster/log/create* -t  | head -n 1)
cat $LATEST_ADMIN_FOLDER/create-cluster.log
ls $LATEST_ADMIN_FOLDER

 # View the admin master node logs
cat $LATEST_ADMIN_FOLDER/10.200.0.3

 # Investigate the preflight checks that bmctl performs before creating the cluster
export LATEST_PREFLIGHT_FOLDER=$(ls -d bmctl-workspace/abm-admin-cluster/log/preflight* -t  | head -n 1)
ls $LATEST_PREFLIGHT_FOLDER

 # Check the connectivity tests for the nodes in your network
cat $LATEST_PREFLIGHT_FOLDER/node-network

# Accessing to admin cluster
export KUBECONFIG=$KUBECONFIG:~/baremetal/bmctl-workspace/abm-admin-cluster/abm-admin-cluster-kubeconfig
kubectx admin=.
kubectl get nodes

kubectl create serviceaccount -n kube-system admin-user
kubectl create clusterrolebinding admin-user-binding --clusterrole cluster-admin --serviceaccount kube-system:admin-user
kubectl create token admin-user -n kube-system
