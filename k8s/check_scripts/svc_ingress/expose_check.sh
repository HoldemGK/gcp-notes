!/bin/bash
# Creation
# k -n web expose deploy web-frontend --name=web-frontend-svc --port=80 --target-port=80 --type=NodePort --record  --dry-run=client -o yaml > svc.yaml
# k -n web create ing web-frontend-ingress --rule="/*=web-frontend-svc:80"  --dry-run=client -o yaml > ing.yaml

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

kubectl get deployment -n web web-frontend -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}' 2>/dev/null | grep 80 >/dev/null 2>/dev/null
printresult "Edit the web-frontend deployment to expose the HTTP port." $?

kubectl get svc web-frontend-svc -n web -o jsonpath='{.spec.selector.app}{.spec.type}{.spec.ports[0].targetPort}{.spec.ports[0].nodePort}' 2>&1 | grep web-frontendNodePort8030080 >/dev/null 2>/dev/null
printresult "Create a Service to expose web-frontend deployment's Pods externally." $?

kubectl get deployment -n web web-frontend -o jsonpath='{.spec.replicas}' 2>/dev/null | grep 5 >/dev/null2>/dev/null
printresult "Scale the web-frontend deployment up." $?

kubectl get ingress -n web web-frontend-ingress -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}{.spec.rules[0].http.paths[0].backend.service.port.number}{.spec.rules[0].http.paths[0].path}' 2>/dev/null | grep web-frontend-svc80/ >/dev/null 2>/dev/null
printresult "Create an Ingress that maps to the new Service." $?