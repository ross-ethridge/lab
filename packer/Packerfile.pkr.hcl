packer {
  required_version = "~> 1"
  required_plugins {
    vsphere = {
      version = "~> 1"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

locals {
  timestamp             = formatdate("MMDDhhmmss", timestamp())
  ssh_username          = "packer"
  vsphere_guest_os_type = "oracleLinux7_64Guest"
  vsphere_image   = "pkrbuild-${local.timestamp}"
}

source "vsphere-iso" "vsphere" {
  CPUs            = 2
  RAM             = 4096
  RAM_reserve_all = false

  boot_command = [
    "<wait5><up><tab>",
    " inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kickstart_cfg hostname=si-vault-pkrtemplate-${local.timestamp} ip=dhcp",
    "<enter><wait>"
  ]

  boot_order = "disk,cdrom,floppy,ethernet"
  boot_wait  = "10s"

  http_content = {
    "/kickstart_cfg" = templatefile("${path.root}/templates/kickstart.cfg.pkrtpl.hcl", {
      PACKER_PASSWORD = var.image_pass
    })
  }

  http_port_min = 1420
  http_port_max = 1420

  cluster             = var.vsphere_cluster
  convert_to_template = true
  datacenter          = var.vsphere_datacenter
  datastore           = var.vsphere_datastore

  disk_controller_type = [
    "lsilogic"
  ]

  folder              = var.vsphere_folder
  guest_os_type       = local.vsphere_guest_os_type
  insecure_connection = true

  iso_paths = [
    var.iso_url_vsphere
  ]

  network_adapters {
    network      = var.vsphere_network
    network_card = "vmxnet3"
  }

  password     = var.vsphere_pass
  remove_cdrom = true
  ssh_username = local.ssh_username
  ssh_password = var.image_pass

  storage {
    disk_size             = 40000
    disk_thin_provisioned = false
  }

  username       = var.vsphere_user
  vcenter_server = var.vsphere_server
  vm_name        = local.vsphere_vault_image
}

// Build from ISO
build {

  sources = [
    "source.vsphere-iso.vsphere"
  ]

  // Copies file directories into place
  provisioner "file" {
    destination = "/home/packer"
    source      = "files/"
  }

  // Adds local dnf repos to image
  provisioner "file" {
    destination = "/home/packer/${var.env}.repo"
    content = templatefile("${path.root}/templates/yum_repos.pkrtpl.hcl", {
      central_repo = var.central_repo,
      env          = var.env
    })
  }

  // Adds template info to image
  provisioner "file" {
    destination = "/home/packer/zos-template-info"
    content = templatefile("${path.root}/templates/zos_template_info.pkrtpl.hcl", {
      template_version = local.vsphere_vault_image,
      datacenter       = var.domain,
      env              = var.env
    })
  }

  // Copies network related files into place
  provisioner "shell" {

    inline = [
      "echo '${var.image_pass}' |sudo -S mv /home/packer/network/zos-release-ips /usr/local/sbin/zos-release-ips",
      "echo '${var.image_pass}' |sudo -S chown root:root /usr/local/sbin/zos-release-ips",
      "echo '${var.image_pass}' |sudo -S chmod +x /usr/local/sbin/zos-release-ips",

      "echo '${var.image_pass}' |sudo -S mv /home/packer/network/zos-release-ips.service /etc/systemd/system/zos-release-ips.service",
      "echo '${var.image_pass}' |sudo -S chown root:root /etc/systemd/system/zos-release-ips.service",
      "echo '${var.image_pass}' |sudo -S chmod 0644 /etc/systemd/system/zos-release-ips.service",

      "echo '${var.image_pass}' |sudo -S mv /home/packer/network/etc_dhcp_dhclient.conf /etc/dhcp/dhclient.conf",
      "echo '${var.image_pass}' |sudo -S chown root:root /etc/dhcp/dhclient.conf",
      "echo '${var.image_pass}' |sudo -S chmod 0644 /etc/dhcp/dhclient.conf",

      "echo '${var.image_pass}' |sudo -S mv /home/packer/network/etc_networkmanager_confd_dhcp_client.conf /etc/NetworkManager/conf.d/dhcp-client.conf",
      "echo '${var.image_pass}' |sudo -S chown root:root /etc/NetworkManager/conf.d/dhcp-client.conf",
      "echo '${var.image_pass}' |sudo -S chmod 0644 /etc/NetworkManager/conf.d/dhcp-client.conf",
    ]
    valid_exit_codes = [0]
  }

  // Copies rsyslog config into place
  provisioner "shell" {

    inline = [
      "echo '${var.image_pass}' |sudo -S mv /home/packer/rsyslog/etc_rsyslog.conf /etc/rsyslog.conf",
      "echo '${var.image_pass}' |sudo -S chown root:root /etc/rsyslog.conf",
      "echo '${var.image_pass}' |sudo -S chmod 0644 /etc/rsyslog.conf"
    ]
    valid_exit_codes = [0]
  }


  // Copies security related files
  provisioner "shell" {

    inline = [
      "echo '${var.image_pass}' |sudo -S mv /home/packer/ssh/etc_ssh_sshd_config /etc/ssh/sshd_config",
      "echo '${var.image_pass}' |sudo -S chown root:root /etc/ssh/sshd_config",
      "echo '${var.image_pass}' |sudo -S chmod 0644 /etc/ssh/sshd_config",

      "echo '${var.image_pass}' |sudo -S mv /home/packer/security/etc_sysconfig_sshd /etc/sysconfig/sshd",
      "echo '${var.image_pass}' |sudo -S chown root:root /etc/sysconfig/sshd",
      "echo '${var.image_pass}' |sudo -S chmod 0644 /etc/sysconfig/sshd",

      "echo '${var.image_pass}' |sudo -S mv /home/packer/security/etc_sysctl.conf /etc/sysctl.conf",
      "echo '${var.image_pass}' |sudo -S chown root:root /etc/sysctl.conf",
      "echo '${var.image_pass}' |sudo -S chmod 0644 /etc/sysctl.conf",

      "echo '${var.image_pass}' |sudo -S systemctl daemon-reload",
      "echo '${var.image_pass}' |sudo -S systemctl restart sshd"
    ]
    valid_exit_codes = [0]
  }


  provisioner "shell" {

    inline = [
      "echo '${var.image_pass}' |sudo -S /usr/bin/rm -f /etc/yum.repos.d/*",
      "echo '${var.image_pass}' |sudo -S mv /home/packer/${var.env}.repo /etc/yum.repos.d/${var.env}.repo",
      "echo '${var.image_pass}' |sudo -S chown root:root /etc/yum.repos.d/${var.env}.repo",
      "echo '${var.image_pass}' |sudo -S chmod 0644 /etc/yum.repos.d/${var.env}.repo"
    ]
    valid_exit_codes = [0]
  }


  // Installs packages to all servers
  provisioner "shell" {

    environment_vars = [
      "vault_version=${var.vault_version}",
      "central_repo=${var.central_repo}",
      "go_version=${var.go_version}",
      "env=${var.env}"
    ]
    script           = "provisioners/install_packages.sh"
    valid_exit_codes = [0]
  }

  provisioner "shell" {

    inline = [
      "echo '${var.image_pass}' |sudo -S mv /home/packer/zos-template-info /etc/zos-template-info",
      "echo '${var.image_pass}' |sudo -S chown root:root /etc/zos-template-info",
      "echo '${var.image_pass}' |sudo -S chmod 0644 /etc/zos-template-info"
    ]
    valid_exit_codes = [0]
  }

  // Adds search domain to network manager
  provisioner "shell" {

    inline = [
      "echo '==> Adding SearchDomain to network interface'",
      "echo '${var.image_pass}'|sudo -S nmcli con mod ens160 ipv4.dns-search ${var.domain}"
    ]
    valid_exit_codes = [0]
  }


  // Microsoft EDR Install
  provisioner "shell" {

    inline = [
      "echo '==> Installing Microsoft EDR'",
      "sudo curl -s http://${var.central_repo}/ZOS_SI/mdatp_onboard.json -o /etc/opt/microsoft/mdatp/mdatp_onboard.json",
      "sudo chown root:root /etc/opt/microsoft/mdatp/mdatp_onboard.json",
      "sudo chmod 0644 /etc/opt/microsoft/mdatp/mdatp_onboard.json",
      "sudo mdatp edr tag set --name GROUP --value ${replace(upper(var.env), "-", "_")}",
      "sudo mdatp config proxy set --value ${var.security_proxy}"
    ]
    valid_exit_codes = [0]
  }


  // Restart networking
  provisioner "shell" {

    inline = [
      "echo 'Restarting networking'",
      "echo '${var.image_pass}' |sudo -S systemctl restart NetworkManager.service",
      "echo '${var.image_pass}' |sudo -S systemctl enable zos-release-ips.service"
    ]
    valid_exit_codes = [0]
  }


  // SPEC Tests / GOSS
  provisioner "shell" {

    inline = [
      "echo '==> Running spec tests'",
      "export vault_version=${var.vault_version}",
      "export version_string=$(printf ${var.vault_version} | cut -d '-' -f4-5)",
      "cd /home/packer/goss",
      "/usr/local/go/bin/goss --vars-inline \"VaultVersion: $version_string\" validate ./goss.yaml"
    ]
    valid_exit_codes = [0]
  }


  // NOTE: This should be one of the last remote provisioners ran
  provisioner "shell" {
    script = "provisioners/cleanup_system.sh"
  }

  post-processor "shell-local" {
    inline = [
      "echo '==> Cleaning up build files'",
      "rm -rf build-keys"
    ]
  }

}