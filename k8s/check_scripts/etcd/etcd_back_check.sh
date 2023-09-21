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

cat /home/cloud_user/etcd_backup.db >/dev/null 2>/dev/null
printresult "Back up the Etcd data." $?

sudo bash -c '[[ "/var/lib/etcd/member/snap/db" -nt "/tmp/time.txt" ]]' >/dev/null 2>/dev/null
printresult "Restore the Etcd data from the backup." $?