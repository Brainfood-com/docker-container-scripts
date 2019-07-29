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

variable "networks" {
	type = list(string)
}

resource "null_resource" "networks" {
	count = length(var.networks)

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
			"docker network inspect ${var.networks[count.index]} || docker network create ${var.networks[count.index]}",
		]
	}
}

output "depended_on" {
	value = join(",", [for n in null_resource.networks: n.id])
}
