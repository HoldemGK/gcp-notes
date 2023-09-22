!/bin/bash
echo -e "Checking Objectives..."
OBJECTIVE_NUM=0
function printresult {
  ((OBJECTIVE_NUM+=1))
  echo -e "\n----- Checking Objective $1 -----"
  echo -e "----- $2"
  if [ $3 -eq 0 ]; then
      echo -e "      \033[0;32m[COMPLETE]\033[0m Congrats! This objective is complete!"
  else
      echo -e "      \033[0;31m[INCOMPLETE]\033[0m This objective is not yet completed!"
  fi
}

kubectl get node acgk8s-worker1 | grep SchedulingDisabled >/dev/null 2>/dev/null
printresult "1" "Drain Worker Node 1." $?

kubectl get pod fast-nginx -n dev -o wide | grep acgk8s-worker2 >/dev/null 2>/dev/null
printresult "2" "Create a Pod that will only be scheduled on nodes with a specific label." $?