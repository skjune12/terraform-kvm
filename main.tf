# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

provider "template" {
  version = "~> 2.1"
}

resource "libvirt_pool" "terraform" {
  name = "terraform"
  type = "dir"
  path = "/var/lib/libvirt/terraform"
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "ubuntu-vm01" {
  name   = "ubuntu-vm01.qcow2"
  pool   = libvirt_pool.terraform.name
  source = "https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "ubuntu-vm02" {
  name   = "ubuntu-vm02.qcow2"
  pool   = libvirt_pool.terraform.name
  source = "https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img"
  format = "qcow2"
}


data "template_file" "vm01_user_data" {
  template = file("${path.module}/vm01/cloud_init.cfg")
}

data "template_file" "vm02_user_data" {
  template = file("${path.module}/vm02/cloud_init.cfg")
}

data "template_file" "vm01_network_config" {
  template = file("${path.module}/vm01/network_config.cfg")
}

data "template_file" "vm02_network_config" {
  template = file("${path.module}/vm02/network_config.cfg")
}

# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "vm01" {
  name           = "vm01.iso"
  user_data      = data.template_file.vm01_user_data.rendered
  network_config = data.template_file.vm01_network_config.rendered
  pool           = libvirt_pool.terraform.name
}

resource "libvirt_cloudinit_disk" "vm02" {
  name           = "vm02.iso"
  user_data      = data.template_file.vm02_user_data.rendered
  network_config = data.template_file.vm02_network_config.rendered
  pool           = libvirt_pool.terraform.name
}

# Create a management network
resource "libvirt_network" "management_network" {
  name   = "mgmt0"
  mode   = "bridge"
  bridge = "br-mgmt0"
}

# Create vm01 machine
resource "libvirt_domain" "vm01_domain" {
  name   = "vm01"
  memory = "512"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.vm01.id

  network_interface {
    bridge = "br0"
  }

  network_interface {
    network_name = "mgmt0"
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-vm01.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# Create vm02 machine
resource "libvirt_domain" "vm02_domain" {
  name   = "vm02"
  memory = "512"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.vm02.id

  network_interface {
    bridge = "br0"
  }

  network_interface {
    network_name = "mgmt0"
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-vm02.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

terraform {
  required_version = ">= 0.12"
}
