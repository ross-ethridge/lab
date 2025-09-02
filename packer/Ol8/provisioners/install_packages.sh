#!/bin/bash

test "$UID" -eq 0 || exec sudo -E bash "$0"

# Install system packages
echo "==> Installing QoL packages that all our servers need"
dnf makecache
package_list=(
  "bash-completion"
  "bind-utils"
  "cloud-init"
  "curl"
  "jq"
  "mlocate"
  "net-tools"
  "NetworkManager"
  "open-vm-tools"
  "rsync"
  "sssd"
  "tree"
  "vim"
  "wget"
  "yum-utils"
  "xorriso"
)
dnf install ${package_list[@]} -y

# Install Development Tools
dnf groupinstall "Development Tools" -y

# Install golang
curl -L https://go.dev/dl/go1.25.0.linux-amd64.tar.gz | tar -C /usr/local -xzvf -
echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a /etc/profile

# Run DNF updates
dnf update -y

# Clean up
dnf autoremove -y
dnf clean all
rm -rf /var/cache/dnf

# Tune cloud-init/vmware
sed -i 's/disable_vmware_customization: false/disable_vmware_customization: true/g' /etc/cloud/cloud.cfg
