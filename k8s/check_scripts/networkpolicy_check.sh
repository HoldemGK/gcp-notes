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

kubectl exec client -n users-backend -- curl -m 1 $(kubectl get pod maintenance -n foo -o jsonpath='{.status.podIP}') 2>&1 | grep "exit code 28" >/dev/null 2>/dev/null
printresult "Create a NetworkPolicy that denies all access to the maintenance Pod." $?

SERVER_POD_IP=$(kubectl get pod server -n users-backend -o jsonpath='{.status.podIP}')
kubectl exec client -n users-backend -- curl -m 1 $SERVER_POD_IP:81 2>&1 | grep "exit code 28" >/dev/null2>/dev/null
actual1=$?
kubectl exec client -n users-backend -- curl -m 1 $SERVER_POD_IP:80 >/dev/null 2>/dev/null
actual2=$?
actual=$(( actual1 + actual2 ))
printresult "Create a NetworkPolicy that allows all Pods in the users-backend Namespace to communicate with each other only on a specific port." $actual