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
kubectl run nginx-yaml --image=nginx --dry-run=client -o yaml | tee pod.yaml

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

## Namespaces
In Kubernetes, namespaces provide a mechanism for isolating groups of resources within a single cluster. Names of resources need to be unique within a namespace, but not across namespaces.
Applications should have their own namespace as a good design pattern.
Think of this as a logical grouping.
```bash
kubectl create namespace mealie --dry-run=client -o yaml | tee namespace.yaml

apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: null
  name: mealie
spec: {}
status: {}
```
To set you context to the namespace that you are working in:
```bash
kubectl config set-context --current --namespace=mealie
```

## Deployments
A Deployment manages a set of Pods to run an application workload, usually one that doesn't maintain state.
A Deployment provides declarative updates for Pods and ReplicaSets.
You describe a desired state in a Deployment, and the Deployment Controller changes the actual state to the desired state at a controlled rate.
```bash
kubectl create deployment mealie --image=nginx --replicas=1 --namespace=mealie --dry-run=client -o yaml | tee mealie-deploy.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: mealie
  name: mealie
  namespace: mealie
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mealie
  template:
    metadata:
      labels:
        app: mealie
    spec:
      containers:
        - image: ghcr.io/mealie-recipes/mealie:v1.2.0
          name: mealie
          ports:
            - containerport: 9000

```
