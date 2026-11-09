terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.121"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true # the cluster uses self-signed certs
}

locals {
  image = "${path.module}/../image/build/openwrt-vigra.raw"
}

# the disk image built by ../image (make); "import" content must be enabled on the storage.
# Each build gets its own file name, and old uploads are left on the storage
# instead of deleted, since our token can't delete files (Datastore.Allocate).
resource "proxmox_virtual_environment_file" "openwrt" {
  node_name    = var.node
  datastore_id = var.storage
  content_type = "import"

  source_file {
    path      = local.image
    file_name = "openwrt-vigra-${substr(filesha256(local.image), 0, 12)}.raw"
  }

  lifecycle {
    destroy = false
  }
}

resource "proxmox_virtual_environment_vm" "vigra" {
  name      = "vigra.ice.land"
  node_name = var.node
  vm_id     = var.vm_id
  pool_id   = "dev-04"
  tags      = ["dev", "ice.land", "router"]

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  on_boot       = true

  operating_system {
    type = "l26"
  }

  cpu {
    cores = 2
    type  = "custom-wrccdc-baseline" # change this if not supported on your cluster
  }

  memory {
    dedicated = 512
  }

  agent {
    enabled = true # qemu guest agent
  }

  disk {
    interface    = "scsi0"
    datastore_id = var.storage
    import_from  = proxmox_virtual_environment_file.openwrt.id
    file_format  = "qcow2"
    size         = 1 # GB
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge = "devext04" # WAN
  }
  network_device {
    bridge = "devint04" # LAN
  }

  serial_device {}

  # the disk is only imported when the VM is created, so a new image means a new VM
  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_file.openwrt]
  }
}
