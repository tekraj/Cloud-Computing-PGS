#!/bin/bash

# Redirect output to a log file so students can debug if it fails
# Log location: /var/log/user-data.log
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting Deployment Script..."

# 1. Update system and install base dependencies
dnf update -y
dnf install -y dnf-plugins-core git docker

# 2. Start and enable Docker service
systemctl enable --now docker

# 3. Add ec2-user to docker group
usermod -aG docker ec2-user

# 4. Install modern Docker Compose and Buildx plugins
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sed -i 's/\$releasever/40/g' /etc/yum.repos.d/docker-ce.repo

dnf download -y docker-compose-plugin docker-buildx-plugin
rpm -ivh --force docker-compose-plugin*.rpm docker-buildx-plugin*.rpm
rm -f docker-compose-plugin*.rpm docker-buildx-plugin*.rpm

# 5. WAIT for Docker to be fully active
# This prevents "Cannot connect to the Docker daemon" errors
while ! docker info >/dev/null 2>&1; do 
  echo "Waiting for Docker daemon..."
  sleep 2
done

# 6. Clone the repository into a specific directory
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app
git clone https://github.com/tekraj/Cloud-Computing-PGS.git .

# 7. Setup environment variables
cat <<EOF > .env
SECRET_KEY=dsafdsafdsafdsa
DEBUG=True
DB_HOST=database-1.cpum1y0g7b8g.us-east-1.rds.amazonaws.com
DB_NAME=ecommerce
DB_USER=admin
DB_PORT=3306
DB_PASSWORD=mauFJcuf5dhRMQrjj
ALLOWED_HOSTS=*
SERVER_NUMBER=3
# Add S3 settings if your Django app uses them
AWS_STORAGE_BUCKET_NAME=your-bucket-name
EOF

# 8. FIX PERMISSIONS BEFORE RUNNING DOCKER
# Ensure ec2-user owns everything
chown -R ec2-user:ec2-user /home/ec2-user/app

# 9. RUN DOCKER AS ROOT (Since User Data runs as root)
# We don't need to wait for a logout/login this way
docker compose build
docker compose up -d

echo "Deployment Complete!"