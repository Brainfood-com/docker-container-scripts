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

variable "packages" {
	type = list(string)
}

resource "null_resource" "packages" {
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
			"if ! dpkg -s ${join(" ", var.packages)} >/dev/null; then apt-get update -q; apt-get install -qy ${join(" ", var.packages)}; fi",
		]
	}
}

output "depended_on" {
	value = null_resource.packages.id
}
