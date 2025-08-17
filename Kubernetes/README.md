# Kube
## Containers
- You typically would not use Kube to just run a single container, but you can still do it:
```bash
kubectl run nginx-ross --image=nginx
```
## Control Plane
- **API server**: Kubectl talks to the API server. The API server listens on port ```:6443```
- **Scheduler**: Placement manager, evaluates constraints and makes sure there are enough resources on the node. API server schedules pods through the ```scheduler```. The scheduler  assigns pods to a node.
- **ETCD**: The backing config data store for the Kube cluster. Facilitates cluster recovery.

## Pods
Pods are the smallest element in Kubernetes. Pods are not containers, they are a collection of containers. You deploy applications into pods. A pod of whale's. The most common pod is a single container however, but they are not synonymous, 
- A pod could be two containers, an init container that checks for connectivity before your application container runs.
- Or an application container, web server container, along with a database container.
- All of the pod members containers share the same storage.

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
  name: mealie

kubectl apply -f namespace.yaml
namespace/mealie configured
```
- To set you context to the namespace that you are working in:
```bash
kubectl config set-context --current --namespace=mealie
```
- To ```view``` your working namespace context:  

```bash
kubectl config view

apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://127.0.0.1:6443
  name: rancher-desktop
contexts:
- context:
    cluster: rancher-desktop
    namespace: mealie
    user: rancher-desktop
  name: rancher-desktop
current-context: rancher-desktop
kind: Config
preferences: {}
users:
- name: rancher-desktop
  user:
    client-certificate-data: DATA+OMITTED
    client-key-data: DATA+OMITTED
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
            - containerPort: 9000
```
- Deploy this deployment:
```bash
kubectl apply -f mealie-deploy.yaml

deployment.apps/mealie created
```
- Check your deployment:
```bash
kubectl get pods

NAME                      READY   STATUS    RESTARTS   AGE
mealie-5479dbb894-72xvc   1/1     Running   0          27s
```
### Port forwarding cheat for a quick test
- This method is not for production use as you have to keep the command running in terminal for this test.

```bash
kubectl port-forward pods/mealie-5479dbb894-72xvc 9000

Forwarding from 127.0.0.1:9000 -> 9000
Forwarding from [::1]:9000 -> 9000
Handling connection for 9000
Handling connection for 9000
Handling connection for 9000
```
## Networking
- Networking happens on the pod level. Kube does not connect individual containers together.
- Each pod gets an IP address.
- By default, pods can connect to all pods on all nodes.
- You can restrict pod communication with network policies.
- Containers in the pod can communicate with each other through ```localhost```, therefore each container needs to be exposed on different port numbers inside the pod.

### CNI Plugins: Container Networking Interface
- Provides the network connectivity to containers.
- Configures the network interfaces in the containers.
- Assigns IP addresses and sets up routing --> Iptables on nodes.
- You can examine ```/etc/cni/net.d``` directory on a node to tell which CNI plugin you are using:
```bash
lima-rancher-desktop:/# tree /etc/cni/net.d

/etc/cni/net.d
└── 10-flannel.conflist
```

### Services
- A service offers a consistent address to access a set of pods.
- Pods are ephemeral. You should not expect a pod to have a long lifespan.
- Pods are constantly changing and moving across nodes.
- We need a mechanism to to keep track of the constantly changing IP addresses of the pods.
- A service works like a grouping of pods.
- You can ```expose``` a service for a deployment from cli:
```bash
kubectl expose deployment frontend --port 8080
```
- You can output the service as yaml:
```bash
k get service/mealie -o yaml | tee service.yaml

apiVersion: v1
kind: Service
metadata:
  labels:
    app: mealie
  name: mealie
  namespace: mealie
spec:
  ports:
  - port: 9000
    protocol: TCP
    targetPort: 9000
  selector:
    app: mealie
  type: LoadBalancer


kubectl apply -f service.yaml 
service/mealie created
```
#### Service Types
- **ClusterIP**: Default. Crates cluster-wide IP for the service.
- **NodePort**: Expose a port on each node allowing direct access to the service through any node's IP address. Not the best due to having to track IP addresses of nodes.
- **LoadBalancer**: Used for cloud providers. Will create an Azure LoadBalancer to route traffic into the cluster.  
(Can also be used for k3s/Rancher Desktop)

### Ingress
- Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster.
- SSL / TLS termination
- External URL's
- Path based routing
- Ingress resource is YAML like everything else
#### Requires an Ingress Controller
- Nginx
- Traefik
- Cilium
- Cloud: Application Gateway Ingress Controller (AGIC)

#### How it works
- Listens for HTTP or HTTPS
- Ingress controllers contain a route to a service endpoint.
- The service endpoint routes the request to the pod.


