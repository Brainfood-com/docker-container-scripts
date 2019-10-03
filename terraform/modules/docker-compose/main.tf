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

resource "null_resource" "docker-compose" {
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
			"wget -q https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m) -O /usr/local/bin/docker-compose",
			"chmod +x /usr/local/bin/docker-compose",
		]
	}
}

output "depended_on" {
	value = null_resource.docker-compose.id
}
