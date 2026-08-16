terraform {
  required_providers {
    virtualbox = {
      source  = "namnd/virtualbox"
      version = "0.2.4"
    }
  }
}

provider "virtualbox" {}

resource "virtualbox_vm" "ubuntu" {
  name   = "terraform-ubuntu-01"
  cpus   = 2
  memory = 2048

  storage_controller {
    name = "SATA Controller"
    type = "sata"
  }
}

resource "virtualbox_disk" "ubuntu_disk" {
  file_path = "C:\\vivek\\terraform-virtualbox-lab\\terraform\\ubuntu.vdi"
  size      = 20000
  format    = "VDI"
}

resource "virtualbox_vm_storage_attachment" "ubuntu_disk_attachment" {
  vm_id           = virtualbox_vm.ubuntu.id
  controller_name = "SATA Controller"
  port            = 0
  device          = 0
  medium          = virtualbox_disk.ubuntu_disk.id
  type            = "hdd"
}

resource "virtualbox_vm_storage_attachment" "ubuntu_iso_attachment" {
  vm_id           = virtualbox_vm.ubuntu.id
  controller_name = "SATA Controller"
  port            = 1
  device          = 0
  medium          = "C:/Users/Vivek/Downloads/ubuntu-26.04-live-server-amd64.iso"
  type            = "dvddrive"
}