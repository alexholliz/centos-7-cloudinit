# centos-7-cloudinit
CentOS 7 Cloud-Init with vSphere Cloud Init GuestInfo

## References
* https://www.packer.io/docs/builders/vmware/vsphere-iso/
* https://www.packer.io/docs/templates/user-variables/
* https://github.com/vmware/cloud-init-vmware-guestinfo
* https://www.reddit.com/r/sysadmin/comments/ea669z/cloudinit_with_terraform_vsphere_centos8/faozvxs/
* https://medium.com/@gmusumeci/how-to-use-packer-to-build-a-centos-template-for-vmware-vsphere-dea37d95b7b1
* https://grantorchard.com/terraform-vsphere-cloud-init/

## Packer File

I'm going to go through this template piece by piece, and sort of break down what each section does. Full files will be at the bottom.

### Variables

This section sets up and contains variables that will be used later in the builder stage of the file.

These variables can be stored as:
* strings: enclosed in quotes
* Environment Variables: enclosed in double brackets.

Additional Detail here: https://www.packer.io/docs/templates/user-variables/
#### Variables Section
```
"variables": {
    "vsphere-server": "vcenter.server",
    "vsphere-user": "vcenter-user@vcenter.server",
    "vsphere-password": "somepassword",
    
    "vsphere-datacenter": "vc-dc01",
    "vsphere-cluster": "vc-dc01-cl01",
    "vsphere-network": "server-network",
    "vsphere-datastore": "vc-ds01",
    "vsphere-folder": "/Templates",
    "vm-name": "centos-7-cloudinit",
    "local-pw": "server"
},
Builders
```

This section basically contains everything that constructs the VM and hands it the kickstart file, but I am going to break it down a little further, because each section can use some explanation.

### VM Info

This is all basic information about the VM itself. When creating a new template, you know that the volumes are going to be different sizes, CPU/Mem are going to be changed, so this is just the bare minimum for the template creation process.

The information here will be used to create a VM in vSphere, which will then be customized by the Kickstart file, and finally the provisioners at the end

Of note:
* type: set to "vsphere-iso" as we want to end up with a vsphere template
* convert_to_template: set to true, as we want this to be marked as a template in the inventory after building


#### VM Info
```
"type": "vsphere-iso",
 
 
"vcenter_server":      "{{user `vsphere-server`}}",
"username":            "{{user `vsphere-user`}}",
"password":            "{{user `vsphere-password`}}",
"insecure_connection": "true",
 
"vm_name": "{{user `vm-name`}}",
"datacenter": "{{user `vsphere-datacenter`}}",
"datastore": "{{user `vsphere-datastore`}}",
"folder": "{{user `vsphere-folder`}}",
"convert_to_template": "true",
"cluster": "{{user `vsphere-cluster`}}",
"network": "{{user `vsphere-network`}}",
"boot_order": "disk,cdrom",
 
"guest_os_type": "centos7_64guest",
 
"ssh_username": "root",
"ssh_password": "{{user `local-pw`}}",
 
"CPUs":             2,
"RAM":              2048,
"RAM_reserve_all": false,
 
"disk_controller_type":  "pvscsi",
"disk_size":        10737,
"disk_thin_provisioned": true,
 
"network_card": "vmxnet3",
```

### ISO Location

This is where the Packer job will pull the iso from, which means yes, we're starting from a generic CentOS 7 iso, and modifying it.

Note:
* iso_urls: Can be set to whatever you like, probably smart to grab one close to where your compute is for building this image. Here's the CentOS Mirrorlist: http://isoredirect.centos.org/centos/7/isos/x86_64/
* iso_checksum: Available from the mirror page for your CentOS iso. It's called sha256sum.txt: http://mirror.dal10.us.leaseweb.net/centos/7.8.2003/isos/x86_64/ Copy the value out and paste it here
* iso_checksum_type: As you can imagine, this should probably be set to the same type as the checksum, given to us by the checksum name

#### ISO URL Section
```
"iso_urls": "http://repo1.dal.innoscale.net/centos/7.8.2003/isos/x86_64/CentOS-7-x86_64-Minimal-2003.iso",
"iso_checksum": "659691c28a0e672558b003d223f83938f254b39875ee7559d1a4a14c79173193",
"iso_checksum_type": "sha256",
```

### Kickstart Section

This is made up of two parts:

    Floppy File: This is the file we're going to pass to the Infrastructure Provider as a floppy disk during boot. This allows us to bootstrap the iso on startup with our configuration file, below.
    Boot Command: This is how the Infrastructure Provider is going to Boot the ISO so it can be customized

#### Kickstart File
* ks.cfg
```
# Install a fresh new system (optional)
install
 
 
# Specify installation method to use for installation
# To use a different one comment out the 'url' one below, update
# the selected choice with proper options & un-comment it
cdrom
 
# Set language to use during installation and the default language to use on the installed system (required)
lang en_US.UTF-8
 
# Set system keyboard type / layout (required)
keyboard en
 
# Configure network information for target system and activate network devices in the installer environment (optional)
# --onboot  enable device at a boot time
# --device  device to be activated and / or configured with the network command
# --bootproto method to obtain networking configuration for device (default dhcp)
# --noipv6  disable IPv6 on this device
# To use static IP configuration,
# network --bootproto=static --ip=10.0.2.15 --netmask=255.255.255.0 --gateway=10.0.2.254 --nameserver 192.168.2.1,192.168.3.1
network --onboot yes --device ens192 --bootproto dhcp --noipv6 --hostname centos-7-cloudinit
 
# Set the system's root password (required) It's ok to leave this here, because the provisioner will change it before generating the template
# Plaintext password is: server
rootpw --iscrypted $6$rhel6usgcb$aS6oPGXcPKp3OtFArSrhRwu6sN8q2.yEGY7AIwDOQd23YCtiz9c5mXbid1BzX9bmXTEZi.hCzTEXFosVBI5ng0
 
# Configure firewall settings for the system (optional)
# --enabled reject incoming connections that are not in response to outbound requests
# --ssh   allow sshd service through the firewall
# firewall --enabled --ssh
firewall --disabled
 
# Set up the authentication options for the system (required)
# --enableshadow  enable shadowed passwords by default
# --passalgo    hash / crypt algorithm for new passwords
# See the manual page for authconfig for a complete list of possible options.
authconfig --enableshadow --passalgo=sha512
 
# State of SELinux on the installed system (optional)
# Defaults to enforcing
selinux --disabled
 
# Set the system time zone (required)
timezone --utc America/Chicago
 
# Specify how the bootloader should be installed (required)
# Plaintext password is: password
bootloader --location=mbr --append="crashkernel=auto rhgb quiet" --password=$6$rhel6usgcb$kOzIfC4zLbuo3ECp1er99NRYikN419wxYMmons8Vm/37Qtg0T8aB9dKxHwqapz8wWAFuVkuI/UJqQBU92bA5C0
autopart --type=lvm
# Initialize all disks
 
clearpart --linux --initlabel
 
# Packages selection
%packages --ignoremissing
Require @Base
@Base
@core
sed
perl
less
dmidecode
bzip2
iproute
iputils
sysfsutils
rsync
nano
mdadm
setserial
man-pages.noarch
findutils
tar
net-tools
tmpwatch
lsof
python
screen
lvm2
curl
ypbind
yp-tools
smartmontools
openssh-clients
acpid
irqbalance
which
bind-utils
ntsysv
ntp
man
open-vm-tools
#mysql
postfix
chkconfig
gzip
%end
# End of %packages section
 
%post
#sudo yum upgrade -y
chkconfig ntpd on
chkconfig sshd on
chkconfig ypbind on
chkconfig iptables off
chkconfig ip6tables off
chkconfig yum-updatesd off
chkconfig haldaemon off
chkconfig mcstrans off
chkconfig sysstat off
# Install vmware guest tools
echo "Installing VM Tools..."
# Install open-vm-tools, required to detect IP when building on ESXi
sudo yum -y install epel-release open-vm-tools perl python python3-pip openssh-server curl
sudo systemctl enable vmtoolsd
sudo systemctl start vmtoolsd
%end
 
# Reboot after the installation is complete (optional)
# --eject attempt to eject CD or DVD media before rebooting
reboot --eject
```

### Boot Command
#### Floppy File and Boot Command
```
"floppy_files": [
  "ks.cfg"
],
"boot_command": [
  "<esc><wait>",
  "linux ks=hd:fd0:/ks.cfg<enter>"
]
```

### Provisioners

All of these are shell provisioners, which are run after the iso has finished being created and kickstarted. Once it reboots, the provisioner will log in and execute the commands listed, you can do a lot more than inline shell, but that's what I am doing here.

Specifically:
* Installing the prerequisites to use cloud-init in the resulting template: cloud-init and python-pip
* Installing the cloud-init-vmware-guestinfo tool to expose the VMWare GuestInfo source to Cloud-Init for provisioning via vsphere
* Running a cloud-init clean to wipe out any instance data, so cloud init will run fresh on next boot


#### Provisioners
```
"provisioners": [
 
 
  {
    "type": "shell",
    "inline": [
      "sudo yum -y install cloud-init python-pip"
    ]
  },
   
  {
    "type": "shell",
    "inline": [
      "curl -sSL https://raw.githubusercontent.com/vmware/cloud-init-vmware-guestinfo/master/install.sh | sudo sh -"
    ]
  },
 
  {
    "type": "shell",
    "inline": [
      "sudo cloud-init clean"
    ]
  }
 
]
```

## Terraform Files

Terraform Version: 0.12

### Extra Config

The biggest difference between a cloud-init-ed template and our more traditional Terraform vSphere template, is that instead of the "Customize" operation, we are using the extra_config section to define a meta-data and user-data file to be passed to the VM for post-boot customization:
#### extra_config

```
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
```

### TFVars

Because we can pull out all that IP address/DNS information, our TFVars file becomes a LOT more generic:
#### terraform.auto.tfvars

```
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
```

### Variables

#### variables.tf

```
variable "vsphere_datacenter" {
}
 
variable "vsphere_user" {
}
 
variable "vsphere_password" {
}
 
variable "vsphere_server" {
}
 
variable "domain_user" {
}
 
variable "resource_pool" {
}
 
variable "environment" {
}
 
variable "envincrement" {
}
 
variable "folder" {
}
 
variable "vm_name" {
}
 
variable "vm_vcpu" {
}
 
variable "vm_memory" {
}
 
variable "vm_guest" {
}
 
variable "vm_disk0_size" {
}
 
variable "vm_disk0_id" {
}
 
variable "vm_disk1_size" {
}
 
variable "vm_disk1_id" {
}
 
variable "dportgroup_name" {
}
 
variable "linux_vm_template" {
}
 
variable "datastore" {
}
 
variable "time_zone" {
}
 
variable "vsphere_vm_firmware" {
}
 
variable "domain" {
}

variable "org_name" {
}
```

## Cloud Init

Cloud Init files are divided into two parts:
* Metadata: Contains Network configuration
* User Data: Contains SSH Keys, Packages, Disk customization, etc.

Here's a better breakdown than I myself would be able to come up with. https://cloudinit.readthedocs.io/en/latest/topics/datasources.html This gist is that "Metadata" contains anything that would be immutable for the instance, and would persist between reboots. Server Name, IP Addresses, DNS Servers, Domain Search Zones, etc... "Userdata", by contrast, would contain anything a User would enter. SSH Keys, Package Installs, Cron Tasks, Password Changes, seriously, the sky is the limit, it is just executed at the user level.

### Metadata

In this example, we set a static IP address in our network range for the CentOS Image, we also set a hostname, and an instance ID.

#### templates/metadata.yml

```
network:
  version: 2
  ethernets:
    ens192:
      dhcp4: false
      addresses:
        - 10.1.1.0/24
      gateway4: 10.1.1.1
      nameservers:
        search:
          - domain.com
        addresses:
          - 10.1.1.8
          - 10.1.1.9
local-hostname: centos-7-cloudinit
instance-id: centos-7-cloudinit
```

### Userdata

Userdata files must ALWAYS start with that #cloud-config hashtag.

In this file, we create an ansible user, and give it a key. At some point we will need to go over that. Then we install sl so that we can see that a package install will actually work. Finally, we do a reboot, because CentOS doesn't respect the cloud init changes for a network adapter until a reboot happens. (note the CentOS specific bug: https://fabianlee.org/2020/03/14/kvm-testing-cloud-init-locally-using-kvm-for-a-centos-cloud-image/)

#### templates/userdata.yaml

```
#cloud-config
users:
  - name: ansible
    ssh-authorized-keys:
     - ssh-rsa PUT IN A KEY
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash

packages:
  - sl

# manually set BOOTPROTO for static IP
# older cloud-config binary has bug?
runcmd:
  - [ sh, -c, 'sed -i s/BOOTPROTO=dhcp/BOOTPROTO=static/ /etc/sysconfig/network-scripts/ifcfg-ens192' ]

power_state:
  timeout: 30
  message: cya
  mode: reboot
```
