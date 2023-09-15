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

expected="nginxredis"
actual=$(kubectl get pod multi -n baz -o jsonpath='{.spec.containers[0].image}{.spec.containers[1].image}' 2>/dev/null)
[[ "$actual" = "$expected" ]]
printresult "Create a multi-container Pod." $?

expected="Logging data"
actual=$(kubectl logs logging-sidecar -n baz -c sidecar 2>/dev/null)
[[ "$actual" = "$expected" ]]
printresult "Create a Pod which uses a sidecar to expose the main container's log file to stdout." $?