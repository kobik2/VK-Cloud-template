data "vkcs_compute_flavor" "compute" {
  name = var.compute_flavor
}

data "vkcs_images_image" "compute" {
  name = var.image_flavor
}

resource "vkcs_compute_keypair" "existing-key" {
  name       = "rsa"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "vkcs_compute_instance" "compute" {
  count             = var.amount
  name              = "compute-instance ${count.index}"
  flavor_id         = data.vkcs_compute_flavor.compute.id
  key_pair          = vkcs_compute_keypair.existing-key.name
  availability_zone = var.availability_zone_name
  security_groups   = ["rule22"]

  block_device {
    uuid                  = data.vkcs_images_image.compute.id
    source_type           = "image"
    destination_type      = "volume"
    volume_type           = "ceph-ssd"
    volume_size           = 8
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    uuid = vkcs_networking_network.local.id
  }

  depends_on = [
    vkcs_networking_network.local,
    vkcs_networking_subnet.subnetwork,
  ]
}

resource "vkcs_networking_floatingip" "fip" {
  count = var.amount
  pool = data.vkcs_networking_network.extnet.name
}

resource "vkcs_compute_floatingip_associate" "fip" {
  count       = var.amount
  floating_ip = vkcs_networking_floatingip.fip[count.index].address
  instance_id = vkcs_compute_instance.compute[count.index].id
}


output "instance_external_ip" {
  value = zipmap(vkcs_compute_instance.compute[*].name, vkcs_compute_floatingip_associate.fip[*].floating_ip)
}

#######################################  loadbalancer  #######################################

resource "vkcs_networking_floatingip" "lb_fip" {
  pool    = data.vkcs_networking_network.extnet.name
  port_id = vkcs_lb_loadbalancer.loadbalancer.vip_port_id
}


output "balancer" {
  value = vkcs_networking_floatingip.lb_fip.address
}