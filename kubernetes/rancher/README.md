# Installing RKE2 cluster
1. Make the ```/etc/rancher/rke2``` directory.
2. Copy the ```values.yaml``` file into the rancher directory
3. Update the ```values.yaml``` file with the correct settings for your environment.
4. Run the command to install the cluster service.
5. Start the ```rke2-server``` service

``` bash
mkdir -p /etc/rancher/rke2

cp config.yaml /etc/rancher/rke2

cd /etc/rancher/rke2

curl -sfL https://get.rke2.io | sh -

systemctl enable rke2-server.service --now
```

## Install Cilium as the CNI
1. Install the cilium cli
2. Install helm
3. Install Cilium using Helm and the values file

```bash
# Cilium CLI Installation
export CLI_ARCH=amd64
export CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)

curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum

tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin

rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

```bash
# Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4

chmod 700 get_helm.sh

./get_helm.sh
```

```bash
# Install cilium
helm repo add cilium https://helm.cilium.io

helm repo update

helm install cilium cilium/cilium --version 1.18.4 --namespace kube-system -f ./cilium-values.yaml 
```

## Add Rancher
```bash
# Create namespace
kubectl create namespace cattle-system

# Add cert-manager (required for Let's Encrypt)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

# Create the Cilium Load Balancer IP Pool
kubectl apply -f cattle-pool.yaml

# Add Rancher Helm repo
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

# Install Rancher with Cilium ingress
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  -f ./rancher-values.yaml

# Wait for Rancher to be deployed
kubectl -n cattle-system rollout status deploy/rancher

# Apply the Ingress resource (if not auto-created by Rancher)
kubectl apply -f network-policy.yaml
```

## Verify the deployment
```bash
# Check Rancher pods
kubectl get pods -n cattle-system

# Check the Ingress and its assigned IP
kubectl get ingress -n cattle-system

# Check the load balancer service created by Cilium
kubectl get svc -n cattle-system

# Check Cilium status
cilium status

# Get the external IP assigned to the ingress
kubectl get ingress rancher -n cattle-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## Access Rancher UI
Once deployed, access Rancher at: `https://rancher.chingadero.com`

The LoadBalancer IP will be assigned from the cattle-pool range (69.169.96.211-69.169.96.212).
Make sure your DNS points rancher.chingadero.com to this IP address.

## Troubleshooting
```bash
# Check ingress controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=cilium-operator

# Check cert-manager logs if TLS issues
kubectl logs -n cert-manager -l app=cert-manager

# Verify Cilium ingress is working
kubectl get ciliumloadbalancerippool -A

# Check events
kubectl get events -n cattle-system --sort-by='.lastTimestamp'
```

## Clone VM's

```bash
govc vm.clone \
-folder /ha-datacenter/vm/ \
-ds /ha-datacenter/datastore/datastore1 \
-vm /ha-datacenter/vm/Ubuntu2403 \
-c 4 -m 8192 \
-net "/ha-datacenter/network/Private VM Network" \
rke1.chingadero.com
```
