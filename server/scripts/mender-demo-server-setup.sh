#!/bin/bash

sudo apt-get update
sudo apt-get install -y git apt-transport-https ca-certificates curl gnupg-agent software-properties-common jq

# install docker engine and docker-compose
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# run Mender demo derver
cd /home/ubuntu/
git clone -b 2.2.1 https://github.com/mendersoftware/integration.git integration-2.2.1
sudo bash -c "cd /home/ubuntu/integration-2.2.1 && ./demo up" &

