variable "name" {
	type = string
	description = "Name for this machine/instance"
}

variable "ssh_keys" {
	type = list(string)
	description = "Which pre-loaded ssh-keys to add to the target machine"
}

variable "image" {
	type = string
	default = "debian-10"
	description = "Base-level operating-system image"
}

variable "type" {
	type = string
	default = "cx11"
	description = ""
}

variable "location" {
	type = string
	default = "nbg1"
	description = "Hetzner region"
}

variable "networks" {
	type = list(object({name=string, ip=string}))
	default = []
	description = "Private network to attach to"
}

variable "service_ips" {
	type = list(string)
	default = []
	description = "Public floating ips to take control of"
}

variable "volumes" {
	type = list(string)
	default = []
	description = "Disks to attach to the machine"
}

data "hcloud_network" "discovered_networks" {
	count = length(var.networks)
	name = var.networks[count.index].name
}

data "hcloud_volume" "discovered_volumes" {
	count = length(var.volumes)
	name = var.volumes[count.index]
}

resource "hcloud_server" "server" {
	name = var.name
	image = var.image
	server_type = var.type
	location = var.location
	# This system is auto-deployed from git, no runtime data needs to be retained
	backups = false
	ssh_keys = var.ssh_keys
}

resource "hcloud_server_network" "srvnetwork" {
	count = length(var.networks)
	server_id = hcloud_server.server.id
	network_id = data.hcloud_network.discovered_networks[count.index].id
	ip = var.networks[count.index].ip
	# TODO: network config on target machine
# ip = "10.0.1.5"
}

resource "hcloud_volume_attachment" "srvvolume" {
	count = length(var.volumes)
	server_id = hcloud_server.server.id
	volume_id = data.hcloud_volume.discovered_volumes[count.index].id
	automount = false
}

resource "null_resource" "skel" {
	triggers = {
		instance = hcloud_server.server.id
	}
	connection {
		host = hcloud_server.server.ipv4_address
		user = "root"
	}
	
	provisioner "file" {
		source = "${path.module}/ssh-config"
		destination = "/etc/skel/.ssh/config"
	}
}

data "hcloud_floating_ip" "floating_ips" {
	count = length(var.service_ips)
	ip_address = var.service_ips[count.index]
}

resource "hcloud_floating_ip_assignment" "master" {
	count = length(var.service_ips)
	server_id = hcloud_server.server.id
	floating_ip_id = data.hcloud_floating_ip.floating_ips[count.index].id
}

locals {
	expanded_addresses = join("", formatlist("\taddress %s/32\n", var.service_ips))
}

resource "null_resource" "enable_floating_ips" {
	triggers = {
		instance = hcloud_server.server.id
	}
	connection {
		host		= hcloud_server.server.ipv4_address
		user		= "root"
		timeout		= "500s"
	}

	provisioner "remote-exec" {
		inline = [
			"ifdown eth0",
			"printf 'iface eth0 inet static\n${local.expanded_addresses}' > /etc/network/interfaces.d/99-service-ips.cfg",
			"ifup eth0",
		]
	}
}
locals {
	all_configured = join(",", concat([hcloud_server.server.id], hcloud_server_network.srvnetwork.*.id, hcloud_volume_attachment.srvvolume.*.id))
}

output "connection" {
	value = {
		instance	= local.all_configured
		host		= hcloud_server.server.ipv4_address
		user		= "root"
	}
}
output "depended_on" {
	value = local.all_configured
}

