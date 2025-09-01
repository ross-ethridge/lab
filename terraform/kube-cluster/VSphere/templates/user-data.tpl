#cloud-config
users:
  - name: rossethridge
    gecos: rossethridge
    groups: users,adm,wheel
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyr5lXBgNi9XWfEWkE9Cdjva238PkcoB9NI/D/FdLpAoy4GsFPIH6nN2hhgFOv98rkDfrVIS0GFmhwcL68TTHyfE11L+1QYx7KiLqNxvMLAfS0SCAnMSwXLnDLHOurJQIhKeSsnsBGQ8X5t3iWNie8KM/w02KRJwS1UlgOAtGSG8uVdkuMiN7u1OwhgbBHXABcGyEicj1MTB/i6AgwvsXFmGfpkgLOUAl4VC873tYm25HDxHAlRfhIiJKT1goTUex8zjdaqeQ+gGD84St7r/W0//jc1fUo8zUaXc8x+MEwP4iLyPlCpW9MNLIwYpujRDxCmneZQPY5Jab5UGCLBp6B Terraform SSH key"
