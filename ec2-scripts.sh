#!/bin/bash

# 1. Update and install dependencies
# Note: 'docker' in AL2023 includes the compose plugin as 'docker compose'
dnf update -y
dnf install -y dnf-plugins-core
dnf install -y git docker
mkdir -p /usr/libexec/docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose
# 2. Start and enable Docker service 
systemctl enable --now docker

# 3. Add ec2-user to docker group so you don't need sudo later
usermod -aG docker ec2-user

# 4. Clone the repository
cd /home/ec2-user
# Using git with full path just in case
git clone https://github.com/tekraj/Cloud-Computing-PGS.git
cd Cloud-Computing-PGS

# 5. Create .env 
cp .env.example .env

# 6. Set permissions so ec2-user owns the files
chown -R ec2-user:ec2-user /home/ec2-user/Cloud-Computing-PGS

# 7. Start Docker services
# Note the space: it is 'docker compose', not 'docker-compose'
docker compose up -d