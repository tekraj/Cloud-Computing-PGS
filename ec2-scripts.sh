#!/bin/bash

# 1. Update system and install base dependencies
dnf update -y
dnf install -y dnf-plugins-core git docker

# 2. Start and enable Docker service
systemctl enable --now docker

# 3. Add ec2-user to docker group
# Note: This takes effect on the NEXT login; the script continues as root
usermod -aG docker ec2-user

# 4. Install modern Docker Compose and Buildx plugins
# This bypasses the Amazon Linux 2023 "buildx version 0.12" limitation
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sed -i 's/\$releasever/40/g' /etc/yum.repos.d/docker-ce.repo

# Download and Force Install to resolve file conflicts with the default docker package
dnf download -y docker-compose-plugin docker-buildx-plugin
rpm -ivh --force docker-compose-plugin*.rpm docker-buildx-plugin*.rpm

# Clean up installer files
rm -f docker-compose-plugin*.rpm docker-buildx-plugin*.rpm

# 5. Clone the repository
# We use the absolute path to ensure we are in the correct home directory
cd /home/ec2-user
git clone https://github.com/tekraj/Cloud-Computing-PGS.git
cd Cloud-Computing-PGS

# 6. Setup environment and permissions
# Define the target file
ENV_FILE=".env"

# Create (or overwrite) the .env file with the content
cat <<EOF > $ENV_FILE
SECRET_KEY=dsafdsafdsafdsa
DEBUG=False
DB_HOST=localhost
DB_NAME=ecommerce
DB_USER=admin
DB_PORT=3306
DB_PASSWORD=mauFJcuf5dhRMQrjj
ALLOWED_HOSTS=localhost
EOF

echo "$ENV_FILE has been created with the specified configuration."

# Ensure all files cloned as 'root' are now owned by 'ec2-user'
chown -R ec2-user:ec2-user /home/ec2-user/Cloud-Computing-PGS
docker compose up -d 

