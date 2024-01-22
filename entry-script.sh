#!bin/bash
yum update -y && yum install -y docker
systemctl start docker
usermod -aG docker ec2-user
docker run -p 8080:80 nginx