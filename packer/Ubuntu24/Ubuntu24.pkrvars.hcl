// vsphere_password   = "" set as env var or; export PKR_VAR_vsphere_password='super-secret'
// vsphere_username   = "" set as env var or; export PKR_VAR_vsphere_username='user@example.com'
// packer_password    = "" set as env var or; export PKR_VAR_packer_password='another-secret'
// packer_username    = "" set as env var or; export PKR_VAR_packer_username='packer'
vsphere_datacenter = "Lab"                                                   # DC name
vsphere_datastore  = "datastore2"                                            # DS name
vsphere_folder     = "Templates/"                                            # Folder
vsphere_host       = "esxi-01.washco-web.com"                                # ESXi host DNS name, can also use cluster directive instead
vsphere_iso_url    = "[datastore2] ISO/ubuntu-24.04.3-live-server-amd64.iso" # ISO of full install of ubuntu
vsphere_network    = "VM Network"                                            # Whatever network you need
vsphere_server     = "vcenter.washco-web.com"                                # Your Vsphere server DNS name
