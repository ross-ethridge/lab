# CKA Notes
- CRI: Container Runtime Interface
- OCI: Open Container Initiative.
- For Kube to orchestrate containers, they have to conform to the OCI standard.
- Docker does not conform to OCI, DockerShim is used.

## ETCD
- Distributed KV store
- Listens on port ```:2379```
- Uses RAFT consensus
- Uses a client ```etcdctl```
```bash
# V2
./etcdctl set key1 value1

# V3 
./etcdctl put key1 value1

./etcdctl get key1
```

