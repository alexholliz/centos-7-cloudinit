#General TerraForm Config
vsphere_datacenter = "vc-dc01"
vsphere_user = "vcenter-user@vcenter.server"
vsphere_server = "vcenter.server"
resource_pool = "vc-dc01-cl01/Resources"
domain = "domain.com"

#Templates
linux_vm_template = "centos-7-cloudinit"

#Environment Config
dportgroup_name = "server-network"
folder = "servers"
datastore = "vc-ds01"
vsphere_vm_firmware = "efi"
time_zone = "20"
org_name = "org"

# VM Config
vm_name = "centos-7-cloudinit"
vm_guest = "centos7_64Guest"
vm_vcpu = "4"
vm_memory = "4096"
vm_disk0_size = "16"
vm_disk0_id = "0"