#!/bin/bash
sudo yum install curl
sudo yum -y update
sudo amazon-linux-extras install -y docker
sudo usermod -a -G docker ec2-user
sudo systemctl start docker
sudo docker network create nginx-proxy
sudo docker run -d -p 80:80 --name nginx-proxy --net nginx-proxy -v /var/run/docker.sock:/tmp/docker.sock jwilder/nginx-proxy
sudo docker run -d --name comedy --expose 80 --net nginx-proxy -e VIRTUAL_HOST=surfingjoe.com surfingjoe/comedy
sudo docker run -d --name design --expose 80 --net nginx-proxy -e VIRTUAL_HOST=design.surfingjoe.com surfingjoe/design
hostnamectl set-hostname Docker-server
