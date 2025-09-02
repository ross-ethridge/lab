# OracleLinux 8.10 kickstart file

#########################
# Required settings
#########################
bootloader --location=mbr
keyboard us
lang en_US.UTF-8
rootpw --lock
timezone UTC

#########################
# Optional settings
#########################
clearpart --all
firewall --disabled
firstboot --disabled
network --bootproto=dhcp

# Disk partitioning information
part /boot --fstype="xfs" --ondisk=sda --size=2048
part pv.116 --fstype="lvmpv" --ondisk=sda --size=40000
volgroup ol8 --pesize=4096 pv.116
logvol / --fstype="xfs" --size=35000 --name=root --vgname=ol8
user --name=packer --shell=/bin/bash --password=${PACKER_PASSWORD} --groups=wheel --home=/home/packer
zerombr

#########################
# Packages
#########################
%packages --ignoremissing --excludedocs --instLangs=en_US.utf8
-kernel-uek
dhcp-client
open-vm-tools
openssh-clients
nmap-ncat
sudo
tcpdump
%end

# Reboot
reboot

#########################
# Post
#########################
%post  --log=/root/postinstall-ks.log

# expire the root account
chage -E0 root

# keep proxy settings through sudo
echo 'Defaults env_keep += "HTTP_PROXY HTTPS_PROXY FTP_PROXY RSYNC_PROXY NO_PROXY"' >> /etc/sudoers

# configure packer user in sudoers
echo "%packer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/packer
chmod 0440 /etc/sudoers.d/packer

# disable root login via SSH
sed -i "s/PermitRootLogin yes/PermitRootLogin without-password/g" /etc/ssh/sshd_config

# configure sshd to prevent timeout delay
echo "UseDNS no" >> /etc/ssh/sshd_config
sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/" /etc/ssh/sshd_config

# configure bash history
cat > /etc/profile.d/zos-profile.sh << EOL
export HISTFILESIZE=10000
export HISTSIZE=10000
export HISTTIMEFORMAT="[%F %T] "
export PROMPT_COMMAND="history -a"
EOL

# disable vi's bracketed paste mode
echo "set t_BE=" >> /etc/virc

# End of POST
%end
