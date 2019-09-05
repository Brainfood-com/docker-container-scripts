terraform {
	required_version = ">= 0.12"
}

variable "vhost_suffix" {
	type = string
	default = ""
}

variable "mail-dev-cert-name" {
	type = string
	default = ""
}

variable "wait_for" {
	type = list(string)
	default = []
}
variable "connection" {
	type = object({
		host = string
		user = string
		instance = string
	})
}

variable "squid" {
	type = bool
	default = false
}

variable "nginx" {
	type = bool
	default = true
}

variable "mail-dev" {
	type = bool
	default = false
}

variable "mail-prod" {
	type = bool
	default = false
}

module "docker-ce" {
	source = "../docker-ce"
	connection = var.connection
	wait_for = var.wait_for
}

module "docker-compose" {
	source = "../docker-compose"
	connection = var.connection
	wait_for = var.wait_for
}

module "apt-install-packages" {
	source = "../apt-install-packages"
	connection = var.connection
	packages = ["git"]
	wait_for = concat(var.wait_for, [
		module.docker-ce.depended_on,
	])
}

module "docker-network" {
	source = "../docker-network"
	connection = var.connection
	networks = compact(["build", var.nginx ? "nginx" : "", var.mail-dev ? "mail-dev" : "", var.mail-prod ? "mail-prod" : ""])
	wait_for = concat(var.wait_for, [
		module.docker-ce.depended_on,
	])
}

resource "null_resource" "container-scripts" {
	depends_on = [module.apt-install-packages.depended_on]

	triggers = {
		instance = var.connection.instance
		wait_for = join(",", var.wait_for)
	}
	connection {
		host		= var.connection.host
		user		= var.connection.user
		timeout		= "500s"
	}

	provisioner "remote-exec" {
		inline = [
			"adduser --disabled-password --gecos \"\" local-dev",
			"cd /home/local-dev && sudo -u local-dev git clone https://github.com/Brainfood-com/docker-container-scripts.git container-scripts",
		]
	}
}

resource "null_resource" "squid-enable" {
	depends_on = [module.docker-network.depended_on]
	count = var.squid ? 1 : 0

	triggers = {
		instance = var.connection.instance
		wait_for = join(",", var.wait_for)
		container_scripts = null_resource.container-scripts.id
	}
	connection {
		host		= var.connection.host
		user		= var.connection.user
		timeout		= "500s"
	}

	provisioner "remote-exec" {
		inline = [
			"cd /home/local-dev/container-scripts/compose/squid && docker-compose --log-level=ERROR build && docker-compose up -d",
		]
	}
}

resource "null_resource" "squid-disable" {
	depends_on = [module.docker-network.depended_on]
	count = var.squid ? 0 : 1

	triggers = {
		instance = var.connection.instance
		wait_for = join(",", var.wait_for)
		container_scripts = null_resource.container-scripts.id
	}
	connection {
		host		= var.connection.host
		user		= var.connection.user
		timeout		= "500s"
	}

	provisioner "remote-exec" {
		inline = [
			"cd /home/local-dev/container-scripts/compose/squid && docker-compose down -v",
		]
	}
}

resource "null_resource" "nginx-enable" {
	depends_on = [module.docker-network.depended_on]
	count = var.nginx ? 1 : 0

	triggers = {
		instance = var.connection.instance
		wait_for = join(",", var.wait_for)
		container_scripts = null_resource.container-scripts.id
		squid-enable = null_resource.squid-enable[0].id
		squid-disable = null_resource.squid-disable[0].id
	}
	connection {
		host		= var.connection.host
		user		= var.connection.user
		timeout		= "500s"
	}

	provisioner "remote-exec" {
		inline = [
			"printf '%s\n' ${var.squid ? "http_proxy=http://http-proxy:3128" : ""} > /home/local-dev/container-scripts/compose/nginx/.env",
			"cd /home/local-dev/container-scripts/compose/nginx && docker-compose --log-level=ERROR build && docker-compose up -d",
		]
	}
}

resource "null_resource" "nginx-disable" {
	depends_on = [module.docker-network.depended_on]
	count = var.nginx ? 0 : 1

	triggers = {
		instance = var.connection.instance
		wait_for = join(",", var.wait_for)
		container_scripts = null_resource.container-scripts.id
	}
	connection {
		host		= var.connection.host
		user		= var.connection.user
		timeout		= "500s"
	}

	provisioner "remote-exec" {
		inline = [
			"cd /home/local-dev/container-scripts/compose/nginx && docker-compose down -v",
		]
	}
}

resource "null_resource" "mail-dev-enable" {
	depends_on = [module.docker-network.depended_on]
	count = var.mail-dev ? 1 : 0

	triggers = {
		instance = var.connection.instance
		wait_for = join(",", var.wait_for)
		container_scripts = null_resource.container-scripts.id
		squid-enable = null_resource.squid-enable[0].id
		squid-disable = null_resource.squid-disable[0].id
	}
	connection {
		host		= var.connection.host
		user		= var.connection.user
		timeout		= "500s"
	}

	provisioner "remote-exec" {
		inline = [
			"printf '%s\nHOSTING_VHOST_SUFFIX=%s\nHOSTING_VHOST_CERT_NAME=%s\n' '${var.squid ? "http_proxy=http://http-proxy:3128" : ""}' '${var.vhost_suffix}' '${var.mail-dev-cert-name}' > /home/local-dev/container-scripts/compose/mail-dev/.env",
			"cd /home/local-dev/container-scripts/compose/mail-dev && docker-compose --log-level=ERROR build && docker-compose up -d",
		]
	}
}

resource "null_resource" "mail-dev-disable" {
	depends_on = [module.docker-network.depended_on]
	count = var.mail-dev ? 0 : 1

	triggers = {
		instance = var.connection.instance
		wait_for = join(",", var.wait_for)
		container_scripts = null_resource.container-scripts.id
		squid-enable = null_resource.squid-enable[0].id
		squid-disable = null_resource.squid-disable[0].id
	}
	connection {
		host		= var.connection.host
		user		= var.connection.user
		timeout		= "500s"
	}

	provisioner "remote-exec" {
		inline = [
			"cd /home/local-dev/container-scripts/compose/mail-dev && docker-compose down -v",
		]
	}
}

resource "null_resource" "mail-prod-enable" {
	depends_on = [module.docker-network.depended_on]
	count = var.mail-prod ? 1 : 0

	triggers = {
		instance = var.connection.instance
		wait_for = join(",", var.wait_for)
		container_scripts = null_resource.container-scripts.id
		squid-enable = null_resource.squid-enable[0].id
		squid-disable = null_resource.squid-disable[0].id
	}
	connection {
		host		= var.connection.host
		user		= var.connection.user
		timeout		= "500s"
	}

	provisioner "remote-exec" {
		inline = [
			"printf '%s\n' ${var.squid ? "http_proxy=http://http-proxy:3128" : ""} > /home/local-dev/container-scripts/compose/mail-prod/.env",
			"cd /home/local-dev/container-scripts/compose/mail-prod && docker-compose --log-level=ERROR build && docker-compose up -d",
		]
	}
}

resource "null_resource" "mail-prod-disable" {
	depends_on = [module.docker-network.depended_on]
	count = var.mail-prod ? 0 : 1

	triggers = {
		instance = var.connection.instance
		wait_for = join(",", var.wait_for)
		container_scripts = null_resource.container-scripts.id
	}
	connection {
		host		= var.connection.host
		user		= var.connection.user
		timeout		= "500s"
	}

	provisioner "remote-exec" {
		inline = [
			"cd /home/local-dev/container-scripts/compose/mail-prod && docker-compose down -v",
		]
	}
}

output "depended_on" {
	value = join(",", [
		null_resource.nginx-enable[0].id,
		null_resource.nginx-disable[0].id,
		null_resource.squid-enable[0].id,
		null_resource.squid-disable[0].id,
		null_resource.mail-dev-enable[0].id,
		null_resource.mail-dev-disable[0].id,
		null_resource.mail-prod-enable[0].id,
		null_resource.mail-prod-disable[0].id,
	])
}
