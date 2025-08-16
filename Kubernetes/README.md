# Kube

## Control Plane
- **API server**: Kubectl talks to the API server. The API server listens on port ```:6443```
- **Scheduler**: Placement manager, evaluates constraints and makes sure there are enough resources on the node. API server schedules pods through the ```scheduler```. The scheduler  assigns pods to a node.
- **ETCD**: The backing config data store for the Kube cluster. Facilitates cluster recovery.

## Pods
Pods are the smallest element in Kubernetes. Pods are not containers, they are a collection of containers. You deploy applications into pods. A pod of whale's. The most common pod is a single container however, but they are not synonymous, 
- A pod could be two containers, an init container that checks for connectivity before your application container runs.
- All of the pod members containers share the same storage.
```bash
kubectl run nginx-ross --image=nginx
```

### Generatting base YAML for pods
Rather than start from scratch, you can output a dry run to get started:
```bash
kubectl run nginx-yaml --image=nginx --dry-run=client -o yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx-yaml
  name: nginx-yaml
spec:
  containers:
  - image: nginx
    name: nginx-yaml
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

## Deployments
