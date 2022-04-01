#!/bin/bash

set -ex

while ! [ -f /var/lib/cloud/instance/boot-finished ]; do
	sleep 1
done
cloud-init status

apt-get update
apt-get install -y git

# container-scripts
getent passwd localdev || adduser --disabled-password --gecos "" localdev
if ! [[ -d /home/localdev/container-scripts/.git ]]; then
	cd /home/localdev
	sudo -u localdev git clone https://github.com/Brainfood-com/docker-container-scripts.git container-scripts
	cd /
fi

# docker
cp -a /home/localdev/container-scripts/terraform/modules/docker-ce/docker-key.asc /etc/apt/trusted.gpg.d/docker-key.asc
echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce
/etc/init.d/docker start
adduser localdev docker

# docker-compose
wget -q https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m) -O /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

