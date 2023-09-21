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

kubectl get sa webautomation -n web >/dev/null 2>/dev/null
printresult "Create a ServiceAccount." $?

# expected='["pods"]["get","watch","list"]' (any order)
objective_2=$(kubectl get clusterrole pod-reader -o jsonpath='{.rules[0].resources}{.rules[0].verbs}' 2>/dev/null)
echo $objective_2 | grep -w pods | grep -w list | grep -w get | grep -w watch > /dev/null 2>\&1
rc_objective_2=$?
[[ "$rc_objective_2" -eq "0" ]]
printresult "Create a ClusterRole that provides read access to pods." $?

kubectl get pods -n web --as=system:serviceaccount:web:webautomation >/dev/null 2>/dev/null
printresult "Bind the ClusterRole to the ServiceAccount so that it can read Pods only in the web Namespace." $?