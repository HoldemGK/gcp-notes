!/bin/bash
echo -e "Checking Objectives..."
OBJECTIVE_NUM=0
function printresult {
  ((OBJECTIVE_NUM+=1))
  echo -e "\n----- Checking Objective $OBJECTIVE_NUM -----"
  echo -e "----- $1"
  if [ $2 -eq 0 ]; then
      echo -e "      \033[0;32m[COMPLETE]\033[0m Congrats! This objective is complete!"
  else
      echo -e "      \033[0;31m[INCOMPLETE]\033[0m This objective is not yet completed!"
  fi
}

kubectl get pv host-storage-pv >/dev/null 2>/dev/null
printresult "Create a PersistentVolume." $?

expected="host-storage-pvc"
actual=$(kubectl get pod pv-pod -n auth -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}' 2>/dev/null)
[[ "$actual" = "$expected" ]]
printresult "Create a Pod that uses the PersistentVolume for storage." $?

expected="200Mi"
actual=$(kubectl get pvc host-storage-pvc -n auth -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null)
[[ "$actual" = "$expected" ]]
printresult "Expand the Pod's PersistentVolumeClaim." $?