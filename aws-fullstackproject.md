# AWS Lab: Building a Scalable 3-Tier Django Web Stack

## Project Objective
Deploy a professional-grade, secure, and scalable Django application. You will hide web servers in a private network, use an Application Load Balancer for traffic, store media in S3, and manage data in a private MySQL RDS instance.

---

## Architecture Overview
* **VPC:** Custom network with 6 subnets across 2 Availability Zones.
* **App Tier:** EC2 instances in private subnets running Dockerized Django.
* **Data Tier:** RDS MySQL in private data subnets.
* **Public Tier:** Application Load Balancer (ALB) and NAT Gateway.
* **Storage:** S3 Bucket for persistent media files.



---

## Phase 1: Networking & Connectivity

### 1. Create the VPC
* **Name:** `Django-Stack-VPC`
* **IPv4 CIDR:** `10.0.0.0/16`

### 2. Create Subnets (Total 6)
| Subnet Name | AZ | CIDR | Type |
| :--- | :--- | :--- | :--- |
| Public-Subnet-1 | AZ-A | `10.0.1.0/24` | For ALB/NAT |
| Public-Subnet-2 | AZ-B | `10.0.2.0/24` | For ALB |
| Private-App-1 | AZ-A | `10.0.3.0/24` | For Django EC2 |
| Private-App-2 | AZ-B | `10.0.4.0/24` | For Django EC2 |
| Private-DB-1 | AZ-A | `10.0.5.0/24` | For RDS MySQL |
| Private-DB-2 | AZ-B | `10.0.6.0/24` | For RDS MySQL |

### 3. Gateways & Routing
1.  **Internet Gateway (IGW):** Create and attach to the VPC.
2.  **NAT Gateway:** Create in `Public-Subnet-1` (Select "Public" and allocate Elastic IP).
3.  **Public Route Table:** Route `0.0.0.0/0` → `IGW`. Associate both **Public Subnets**.
4.  **Private Route Table:** Route `0.0.0.0/0` → `NAT Gateway`. Associate both **App** and both **DB subnets**.

---

## Phase 2: Security Groups (The Firewalls)

Create three Security Groups in this order:

1.  **ALB-SG:** Allow **HTTP (80)** from `0.0.0.0/0`.
2.  **App-SG:** Allow **HTTP (80)** ONLY from the `ALB-SG`.
3.  **DB-SG:** Allow **MySQL (3306)** ONLY from the `App-SG`.

---

## Phase 3: Storage & Database

### 1. S3 Bucket
* Create a bucket named `django-media-[student-name]`.
* Enable Public Access.

### 2. RDS MySQL (Free Tier)
1.  **Subnet Group:** Create an RDS Subnet Group containing `Private-DB-1` and `Private-DB-2`.
2.  **Create Database:** * Engine: **MySQL**.
    * Template: **Free Tier**.
    * DB Instance ID: `django-db`.
    * Master Username: `admin` | Password: `mauFJcuf5dhRMQrjj`.
    * **Connectivity:** Choose your VPC and the Subnet Group created above.
    * **Public Access:** No.
    * **Security Group:** Select `DB-SG`.
    * **Initial Database Name:** `ecommerce`.

---

## Phase 4: Compute & Deployment

### 1. IAM Role
* Create an IAM Role for **EC2**.
* Attach `AmazonS3FullAccess`.
* Name it `EC2-S3-Role`.

### 2. Launch EC2 Instances
* **Quantity:** 2 Instances.
* **Subnet:** `Private-App-1` and `Private-App-2`.
* **IAM Role:** `EC2-S3-Role`.
* **Security Group:** `App-SG`.
* **User Data:** Paste the script below (Update the `DB_HOST` and `AWS_STORAGE_BUCKET_NAME`).

```bash
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
DB_HOST=[your db host name]
DB_NAME=ecommerce
DB_USER=admin
DB_PORT=3306
DB_PASSWORD=mauFJcuf5dhRMQrjj
ALLOWED_HOSTS=*
SERVER_NUMBER=[server number]
AWS_STORAGE_BUCKET_NAME=[your-bucket-name]
EOF

# 8. FIX PERMISSIONS BEFORE RUNNING DOCKER
# Ensure ec2-user owns everything
chown -R ec2-user:ec2-user /home/ec2-user/app

# 9. RUN DOCKER AS ROOT (Since User Data runs as root)
# We don't need to wait for a logout/login this way
docker compose build
docker compose up -d

echo "Deployment Complete!"