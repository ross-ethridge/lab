## Monitoring the cluster
- Monitoring the cluster with Prometheus and Grafana is easiest using the Helm chart for the service.
- Install helm on your local system (*not on the Kube cluster)
```bash
# sudo snap install helm --classic
```
- Add the Helm repo we need for Prometheus and Grafana stack
```bash
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```
- Update Helm and install the chart you need for Prometheus/Grafana into its own namespace
```bash
# helm repo update

# helm search repo prometheus-community

# helm install prometheus-stack prometheus-community/kube-prometheus-stack --namespace=monitoring --create-namespace

kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace monitoring get pods -l "release=prometheus-stack"

Get Grafana 'admin' user password by running:

  kubectl --namespace monitoring get secrets prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```
## Exposing the monitoring services outside the cluster
- When we deploy the Helm chart, all the services are ClusterIP servvices. We can expose them for our load balancer by making ```NodePort``` services for UI elements.
```bash
kubectl get svc -n monitoring
NAME                                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                         AGE
alertmanager-operated                       ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP      128m
prometheus-operated                         ClusterIP   None             <none>        9090/TCP                        128m
prometheus-stack-grafana                    ClusterIP   10.97.56.73      <none>        80/TCP                          128m
prometheus-stack-kube-prom-alertmanager     ClusterIP   10.101.107.39    <none>        9093/TCP,8080/TCP               128m
prometheus-stack-kube-prom-operator         ClusterIP   10.105.147.252   <none>        443/TCP                         128m
prometheus-stack-kube-prom-prometheus       ClusterIP   10.103.234.94    <none>        9090/TCP,8080/TCP               128m
prometheus-stack-kube-state-metrics         ClusterIP   10.107.198.218   <none>        8080/TCP                        128m
prometheus-stack-prometheus-node-exporter   ClusterIP   10.101.193.50    <none>        9100/TCP                        128m
```
- We can create the base yaml for all the services by outputting a dry run to file.
```bash
kubectl -n monitoring expose service prometheus-stack-grafana --type=NodePort --target-port=3000 --name=grafana-node-port-service --dry-run=client -o yaml | tee grafana-service.yaml

kubectl -n monitoring expose service prometheus-stack-kube-prom-prometheus --type=NodePort --target-port=9090 --name=prometheus-node-port-service --dry-run=client -o yaml | tee prom-service.yaml

kubectl -n monitoring expose service prometheus-stack-kube-prom-alertmanager --type=NodePort --target-port=9093 --name=alertman-node-port-service --dry-run=client -o yaml | tee alertman-service.yaml
```
- Then we can apply the services at once in the monitoring namespace with ```kubectl```:
```bash
kubectl apply -f .
```
- The services should be visible on every NodePort with the port I defined as nodePort in the yaml files.
    - Prometheus on ports 30600, 30601
    - AlertManager on ports 30602, 30603
    - Grafana on port 30604
```bash
# kubectl get svc -n monitoring | grep NodePort

alertman-node-port-service                  NodePort    10.96.109.11     <none>        9093:30602/TCP,8080:30603/TCP   56m
grafana-node-port-service                   NodePort    10.100.171.180   <none>        3000:30604/TCP                  46m
prometheus-node-port-service                NodePort    10.108.37.234    <none>        9090:30600/TCP,8080:30601/TCP   67m
```
- Should now be able to reach the above services at any node on the cluster.