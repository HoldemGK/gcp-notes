## Installing Elasticsearch and Kibana

```
helm repo add elastic https://helm.elastic.co
helm install elasticsearch elastic/elasticsearch
helm install kibana elastic/kibana
```

## DaemonSet
```
fluentd-ds.yaml
```
In this example, we’re mounting two volumes: one at /var/log and another at /var/log/docker/containers, where the system components and Docker runtime put the logs, respectively.
