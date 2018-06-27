#!/usr/bin/env bash
# The script is developed to automate Mender production server setup
# It's fully based on official documentation
# https://docs.mender.io/1.5/administration/production-installation
# Currently tested on Ubuntu 16.04 and Mender 1.5.0
# @author alex@olmi

set -e

# TODO:
# 1. accept mandatory parameters through options or env vars
# 2. check we are running on ubuntu
# 3. check if current user has sudo to root access
# 4. add rpm based distribution support

export CERT_API_CN=lets.mender.it
export CERT_STORAGE_CN=s3.mender.it
USER_NAME=myusername@host.com
USER_PASSWORD=mysecretpassword

cd /opt

# install required software
echo -e "\n>> Installing required software...\n"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common pwgen git
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# add user to docker group if it's initial instance setup
if [ "$(ls -1 /home | wc -l)" -eq 1 ] && [[ $- != *i* ]]; then
    sudo usermod -aG docker $(ls -1 /home)
fi

# clone git repo
echo -e "\n>> Clonning git repo...\n"
git clone -b 1.5.0 https://github.com/mendersoftware/integration mender-server
cd mender-server
cp -a template production
cd production

# generate keys and passwords
echo -e "\n>> Generating keys and passwords...\n"
../keygen
PASSWORD=$(pwgen 16 1)

# make required changes in configuration
echo -e "\n>> Modifying configuration file...\n"
sed -i -e 's#/template/#/production/#g' prod.yml
sed -i "s/- set-my-alias-here.com/- ${CERT_STORAGE_CN}/g" ./prod.yml
sed -i "s/MINIO_ACCESS_KEY:/MINIO_ACCESS_KEY: mender-deployments/g" ./prod.yml
sed -i "s/MINIO_SECRET_KEY:/MINIO_SECRET_KEY: ${PASSWORD}/g" ./prod.yml
sed -i "s/DEPLOYMENTS_AWS_AUTH_KEY:/DEPLOYMENTS_AWS_AUTH_KEY: mender-deployments/g" ./prod.yml
sed -i "s/DEPLOYMENTS_AWS_AUTH_SECRET:/DEPLOYMENTS_AWS_AUTH_SECRET: ${PASSWORD}/g" ./prod.yml
sed -i "s/DEPLOYMENTS_AWS_URI: https:\/\/set-my-alias-here.com/DEPLOYMENTS_AWS_URI: https:\/\/${CERT_STORAGE_CN}:9000/g" ./prod.yml
sed -i "s/ALLOWED_HOSTS: my-gateway-dns-name/ALLOWED_HOSTS: ${CERT_API_CN}/g" ./prod.yml

# create persistent volumes
echo -e "\n>> Creating persistent volumes...\n"
sudo docker volume create --name=mender-artifacts
sudo docker volume create --name=mender-deployments-db
sudo docker volume create --name=mender-useradm-db
sudo docker volume create --name=mender-inventory-db
sudo docker volume create --name=mender-deviceadm-db
sudo docker volume create --name=mender-deviceauth-db
sudo docker volume create --name=mender-elasticsearch-db
sudo docker volume create --name=mender-redis-db

# start all services
echo -e "\n>> Starting services...\n"
sudo ./run up -d

# wait while containers are up and initialized
echo -e "\n>> Waiting for initialization...\n"
SOUT=./$(basename $0).tmp
COUNT=60
EXIT_CODE=-1
START_TIME=$(date +%s)
set +e
while [ $COUNT -gt 0 ]; do
    if curl -k -I https://127.0.0.1/ui/ 2>/dev/null | grep -E ^HTTP | cut -d' ' -f2 > $SOUT; then
        [ "$(cat $SOUT)" == "200" ] && { EXIT_CODE=0; sleep 5; break; }
    fi
    sleep 2
    let COUNT=${COUNT}-1
done
set -e
rm -f $SOUT
END_TIME=$(date +%s)
DURATION=$(($END_TIME - $START_TIME))
[[ $COUNT -eq 0 && $EXIT_CODE -ne 0 ]] && { echo "[ERROR] Environment didn't UP for $DURATION seconds."; exit 1; }

# create user in Mender application
echo -e "\n>> Creating user...\n"
sudo ./run exec -T mender-useradm /usr/bin/useradm create-user --username=$USER_NAME --password=$USER_PASSWORD

echo -e "\n>> Done!\n"
