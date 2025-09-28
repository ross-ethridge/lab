#cloud-config
users:
  - name: rossethridge
    gecos: 'Ross Ethridge'
    groups: users,adm,wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - "${build_key_pub}"
