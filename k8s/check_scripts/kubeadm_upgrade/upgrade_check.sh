#!/bin/bash
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

expected=2
actual=$(kubectl version | grep 1.27.2 | wc -l 2>/dev/null)
[[ "$actual" = "$expected" ]]
printresult "Upgrade all Kubernetes components on the control plane node." $?

expected=3
actual=$(kubectl get nodes | grep 1.27.2 | wc -l 2>/dev/null)
[[ "$actual" = "$expected" ]]
printresult "Upgrade all Kubernetes components on the worker node." $?