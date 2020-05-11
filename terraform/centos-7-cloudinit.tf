provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.dportgroup_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "linux-vm-template" {
  name          = var.linux_vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "centos-7-cloudinit" {
  name = "${var.vm_name}"

  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  folder   = var.folder
  num_cpus = var.vm_vcpu
  memory   = var.vm_memory
  guest_id = var.vm_guest

  scsi_type = data.vsphere_virtual_machine.linux-vm-template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.linux-vm-template.network_interface_types[0]
  }

  disk {
    label            = "${var.vm_name}-${var.environment}-${var.envincrement}.vmdk"
    size             = var.vm_disk0_size
    unit_number      = var.vm_disk0_id
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.linux-vm-template.id
  }

  extra_config = {
      "guestinfo.metadata"          = base64gzip(file("${path.module}/templates/metadata.yaml"))
      "guestinfo.metadata.encoding" = "gzip+base64"
      "guestinfo.userdata"          = base64gzip(file("${path.module}/templates/userdata.yaml"))
      "guestinfo.userdata.encoding" = "gzip+base64"
  }
}

