# Deploying the Cluster
- The Terraform code will deploy a four node cluster on micro-cloud using the LXD provider.
- The Cluster consists of one node running as the control plane and three worker nodes.
- It uses CloudInit to install the required packages.
```bash
# lxc list

+-------------+---------+----------------------+------+-----------------+-----------+---------------+
|    NAME     |  STATE  |         IPV4         | IPV6 |      TYPE       | SNAPSHOTS |   LOCATION    |
+-------------+---------+----------------------+------+-----------------+-----------+---------------+
| kubemaster  | RUNNING | 240.2.0.146 (enp5s0) |      | VIRTUAL-MACHINE | 0         | microcloud-01 |
+-------------+---------+----------------------+------+-----------------+-----------+---------------+
| kubeworker0 | RUNNING | 240.2.0.77 (enp5s0)  |      | VIRTUAL-MACHINE | 0         | microcloud-01 |
+-------------+---------+----------------------+------+-----------------+-----------+---------------+
| kubeworker1 | RUNNING | 240.2.0.157 (enp5s0) |      | VIRTUAL-MACHINE | 0         | microcloud-01 |
+-------------+---------+----------------------+------+-----------------+-----------+---------------+
| kubeworker2 | RUNNING | 240.2.0.140 (enp5s0) |      | VIRTUAL-MACHINE | 0         | microcloud-01 |
+-------------+---------+----------------------+------+-----------------+-----------+---------------+
```

- To initialize the cluster we need to run this command from the kubemaster:
```bash
# kubeadm init --control-plane-endpoint=$(hostname -f) --node-name=$(hostname -f) --pod-network-cidr=10.244.0.0/16
```

## Join Nodes to the Cluster
- Now we join our worker nodes to the cluster
- To get the join command, run this from the KubeMaster:
```bash
# kubeadm token create --print-join-command

kubeadm join 240.2.0.146:6443 --token nimjjy.h7xxxxxxxxx --discovery-token-ca-cert-hash sha256:9f9996006a105b50523385ca2c8a8blahblah77777
```

### Check the Cluster Status
- Run the above command on all of your worker nodes
- Now you should see your nodes from the KubeMaster
```bash
# kubectl get nodes -o wide

kubectl get nodes -o wide
NAME          STATUS   ROLES           AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
kubemaster    Ready    control-plane   150m   v1.34.0   240.2.0.146   <none>        Ubuntu 24.04.3 LTS   6.8.0-71-generic   containerd://1.7.27
kubeworker0   Ready    <none>          18m    v1.34.0   240.2.0.77    <none>        Ubuntu 24.04.3 LTS   6.8.0-71-generic   containerd://1.7.27
kubeworker1   Ready    <none>          17m    v1.34.0   240.2.0.157   <none>        Ubuntu 24.04.3 LTS   6.8.0-71-generic   containerd://1.7.27
kubeworker2   Ready    <none>          16m    v1.34.0   240.2.0.140   <none>        Ubuntu 24.04.3 LTS   6.8.0-71-generic   containerd://1.7.27
```

## Install a CNI [like flannel]
- note: Run as root [mileage may vary]
```bash
# kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

namespace/kube-flannel created
serviceaccount/flannel created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds created
```

- If you need to restart the CNI daemonset for some reason:
```bash
# kubectl -n kube-flannel rollout restart ds/kube-flannel-ds

daemonset.apps/kube-flannel-ds restarted
```

- You should see flannel running on each node.
```bash
# kubectl get pods --all-namespaces

NAMESPACE      NAME                                     READY   STATUS    RESTARTS   AGE
kube-flannel   kube-flannel-ds-gnhzs                    1/1     Running   0          57s
kube-flannel   kube-flannel-ds-kgcdd                    1/1     Running   0          43s
kube-flannel   kube-flannel-ds-m28xg                    1/1     Running   0          79s
kube-flannel   kube-flannel-ds-mspw4                    1/1     Running   0          4m36s
kube-system    coredns-66bc5c9577-9wrsb                 1/1     Running   0          6m30s
kube-system    coredns-66bc5c9577-wjndc                 1/1     Running   0          6m30s
kube-system    etcd-kubemaster.lxd                      1/1     Running   0          6m39s
kube-system    kube-apiserver-kubemaster.lxd            1/1     Running   0          6m39s
kube-system    kube-controller-manager-kubemaster.lxd   1/1     Running   0          6m39s
kube-system    kube-proxy-64zzb                         1/1     Running   0          57s
kube-system    kube-proxy-dwrzm                         1/1     Running   0          43s
kube-system    kube-proxy-f7mvm                         1/1     Running   0          6m31s
kube-system    kube-proxy-f8x4f                         1/1     Running   0          79s
kube-system    kube-scheduler-kubemaster.lxd            1/1     Running   0          6m39s
```

## Deploy a Pod and Test
- Lets deploy a pod and see if it works?
```bash
# nginx-pod-storage.yaml
# Nginx pod with a storoage volume
-
apiVersion: v1
kind: Pod
metadata:
  labels:
  name: nginx-storage
spec:
  containers:
    - image: nginx
      name: nginx
      volumeMounts:
        - mountPath: /scratch
          name: scratch-volume
    - image: busybox
      name: busybox
      command: ["/bin/sh", "-c"]
      args: ["sleep 1000"]
      volumeMounts:
        - mountPath: /scratch
          name: scratch-volume
  volumes:
    - name: scratch-volume
      emptyDir:
        sizeLimit: 500Mi
```

- Lets send it.
```bash
# kubectl apply -f nginx-pod-storage.yaml

pod/nginx-storage created


```
