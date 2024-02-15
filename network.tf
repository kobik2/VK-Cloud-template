data "vkcs_networking_network" "extnet" {
   name = "ext-net"
}

resource "vkcs_networking_network" "local" {
   name = "net"
}

resource "vkcs_networking_subnet" "subnetwork" {
   name       = "subnet_1"
   network_id = vkcs_networking_network.local.id
   cidr       = "192.168.199.0/24"
}

resource "vkcs_networking_router" "router" {
   name                = "router"
   admin_state_up      = true
   external_network_id = data.vkcs_networking_network.extnet.id
}

resource "vkcs_networking_router_interface" "db" {
   router_id = vkcs_networking_router.router.id
   subnet_id = vkcs_networking_subnet.subnetwork.id
   #loadbalancer_id = vkcs_lb_loadbalancer.loadbalancer.id
}


resource "vkcs_networking_secgroup" "secgroup" {
   name = "rule22"
   description = "terraform security group"
}

resource "vkcs_networking_secgroup_rule" "rule_22" {
   direction = "ingress"
   port_range_max = 22
   port_range_min = 22
   protocol = "tcp"
   remote_ip_prefix = "0.0.0.0/0"
   security_group_id = vkcs_networking_secgroup.secgroup.id
   description = "open 22 port"
}


resource "vkcs_networking_port" "port" {
   name = "port_1"
   admin_state_up = "true"
   network_id = vkcs_networking_network.local.id

   fixed_ip {
   subnet_id =  vkcs_networking_subnet.subnetwork.id
   ip_address = "192.168.199.23"
   }
}

resource "vkcs_networking_port_secgroup_associate" "port" {
   port_id            = vkcs_networking_port.port.id
   enforce            = "false"
   security_group_ids = [
   vkcs_networking_secgroup.secgroup.id,
   ]
}

#######################################  loadbalancer  #######################################
resource "vkcs_lb_loadbalancer" "loadbalancer" {
  name          = "loadbalancer"
  vip_subnet_id = vkcs_networking_subnet.subnetwork.id
}

resource "vkcs_lb_listener" "loadbalancer_listener" {
  name            = "loadbalancer_listener"
  description     = "A load balancer frontend that listens on 80 prot for client traffic"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = vkcs_lb_loadbalancer.loadbalancer.id
}

resource "vkcs_lb_pool" "loadbalancer_pool" {
  name        = "loadbalancer_pool"
  description = "A load balancer pool of backends with Round-Robin algorithm to distribute traffic to pool's members"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = vkcs_lb_listener.loadbalancer_listener.id
}

resource "vkcs_lb_member" "loadbalancer_member" {
  count         = var.amount
  name          = "loadbalancer_member-${count.index}"
  address       = vkcs_compute_instance.compute.*.access_ip_v4[count.index]
  protocol_port = 80
  weight        = 10
  pool_id       = vkcs_lb_pool.loadbalancer_pool.id
  subnet_id     = vkcs_networking_subnet.subnetwork.id

  lifecycle {
    create_before_destroy = true
  }
}

