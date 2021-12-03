#!/bin/bash


###########################################################
#	Install docker and run node-exporter container	      #
###########################################################
sudo yum install -y yum-utils
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install docker-ce docker-ce-cli containerd.io -y

sudo systemctl start docker

docker run -d -p 9100:9100 --name node-exporter --restart always prom/node-exporter
