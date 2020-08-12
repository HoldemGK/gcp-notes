#!/bin/bash
docker pull ${JIRA_IMAGE}
docker tag ${JIRA_IMAGE} ${GCR_IMAGE}
docker push ${GCR_IMAGE}
docker rmi ${GCR_IMAGE}
docker rmi ${JIRA_IMAGE}
