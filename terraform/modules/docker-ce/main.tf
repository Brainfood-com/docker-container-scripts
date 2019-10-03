terraform {
	required_version = ">= 0.12"
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

module "apt-install-packages" {
	source = "../apt-install-packages"
	connection = var.connection
	packages = ["apt-transport-https"]
	wait_for = var.wait_for
}

resource "null_resource" "docker-ce" {
	triggers = {
		apt-install-packages = module.apt-install-packages.depended_on
		instance = var.connection.instance
		wait_for = join(",", var.wait_for)
	}
	connection {
		host		= var.connection.host
		user		= var.connection.user
		timeout		= "500s"
	}
	provisioner "file" {
		source = "${path.module}/docker-key.asc"
		destination = "/etc/apt/trusted.gpg.d/docker-key.asc"
	}

	provisioner "remote-exec" {
		inline = [
			"echo \"deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable\" > /etc/apt/sources.list.d/docker.list",
			"apt-get update -q",
			"apt-get install -qy docker-ce",
			"/etc/init.d/docker start",
		]
	}
}

output "depended_on" {
	value = null_resource.docker-ce.id
}
