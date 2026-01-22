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
In this phase, we build the "virtual data center" where your application will live.

### 1. Create the VPC
* **Navigate to:** `VPC Dashboard` > `Your VPCs` > `Create VPC`.
* **Settings:** * Select **VPC only**.
    * **Name tag:** `Django-Stack-VPC`
    * **IPv4 CIDR:** `10.0.0.0/16`


### 2. Create Subnets
* **Navigate to:** `VPC Dashboard` > `Subnets` > `Create subnet`.
* Create **6 subnets** using the table below. 

| Subnet Name | Availability Zone | CIDR Block | Type |
| :--- | :--- | :--- | :--- |
| `Public-Subnet-1` | AZ-A | `10.0.1.0/24` | Public (ALB/NAT) |
| `Public-Subnet-2` | AZ-B | `10.0.2.0/24` | Public (ALB) |
| `Private-App-1` | AZ-A | `10.0.3.0/24` | Private (Django EC2) |
| `Private-App-2` | AZ-B | `10.0.4.0/24` | Private (Django EC2) |
| `Private-DB-1` | AZ-A | `10.0.5.0/24` | Private (RDS MySQL) |
| `Private-DB-2` | AZ-B | `10.0.6.0/24` | Private (RDS MySQL) |



### 3. Gateways & Routing
1. **Navigate to:** `VPC Dashboard` > `Internet Gateways` > `Create Internet Gateway`.
2.  **Internet Gateway (IGW):** Create `Django-IGW` and then use **Actions** > **Attach to VPC** (`Django-Stack-VPC`).
3. **Navigate to:** `VPC Dashboard` > `NAT Gateways` > `Create NAT Gateway`.
  -   Select Regional.
  - Select your VPC
  - Create
5.  **Route Tables:**
Navigate to `VPC Dashboard` > `Route Tables` > `Create Route Table`.
6. **Public-RT:** Create a route table named `Public-RT` and associate it with both **Public subnets**.
  - **Public-RT:** Add route `0.0.0.0/0` → `Target: Internet Gateway`. Associate with `Public-Subnet-1` & `2`.
7.  **Private-RT:** Create a route table named `Private-RT` and associate it with all 4 **Private subnets** (App and DB).
      * **Private-RT:** Add route `0.0.0.0/0` → `Target: NAT Gateway`. Associate with 2  **Private subnets** (App1 and 2).

---

## Phase 2: Security Groups (The Firewalls)
We will use **Security Group Referencing**. Instead of allowing IP ranges, we allow "the ID of the other security group."

### 1. ALB-SG (The Entry Point)
Navigate to `EC2 Dashboard` > `Security Groups` > `Create Security Group`.
* **Name:** `ALB-SG`.
* **Inbound Rule:** * **Type:** `HTTP`
    * **Port:** `80`
    * **Source:** `0.0.0.0/0`
* **Purpose:** Allows public internet traffic to reach the Load Balancer.

### 2. App-SG (The Django Tier)
* **Name:** `App-SG`.
* **Inbound Rule:** * **Type:** `Custom TCP` or `HTTP`
    * **Port:** `80` (or `8000` for Gunicorn)
    * **Source:** `Custom` > Select **ALB-SG**.
* **Purpose:** Ensures only the Load Balancer can communicate with your Django instances.

### 3. DB-SG (The Database Tier)
* **Inbound Rule:** * **Type:** `MySQL/Aurora`
    * **Port:** `3306`
    * **Source:** `Custom` > Select **App-SG**.
* **Purpose:** Only the application servers can query the database.

---

## Summary of Traffic Flow
1. **User** → (Port 80) → **ALB**
2. **ALB** → (Port 80/8000) → **Django EC2**
3. **Django EC2** → (Port 3306) → **RDS MySQL**

## Phase 3: Storage & Database

### 1. S3 Bucket
* Create a bucket named `djangomedia[addyournamehere]`.
  - Disable object ownership
  - enable public access

### 2. RDS MySQL (Free Tier): Search for RDS in AWS Search Bar

1.  **Subnet Group:** Navigate to `RDS Dashboard` > `Subnet Groups` > `Create Subnet Group`.
 Create an RDS Subnet Group containing `Private-DB-1` and `Private-DB-2`.
2.  **Create Database:** * Engine: **MySQL**.
    * Template: **Free Tier**.
    * DB Instance ID: `django-db`.
    * Master Username: `admin` | Password: `mauFJcuf5dhRMQrjj`.
    * **Connectivity:** Choose your VPC and the Subnet Group created above.
    * **Public Access:** No.
    * **Security Group:** Select `DB-SG`.
    * **Initial Database Name:** `ecommerce`.

---

## Phase 4: Target Groups and Load Balancer
Search Target Groups in AWS Search Bar
Select Target Groups(EC2 Feature)
### 1. Create Target Group
* **Name:** `Django-App-TG`.
* **Target Type:** Instances.
* **Protocol:** HTTP | Port: 80.
* **VPC:** Select your VPC.
* **Health Check Path:** `/health/`
### 2. Create Application Load Balancer
Search Load Balancers in AWS Search Bar
Select Load Balancers(EC2 Feature)
Select Create Load Balancer > Application Load Balancer
* **Name:** `Django-ALB`.
* **Scheme:** Internet-facing.
* **IP Address Type:** IPv4.
* **Listeners:** HTTP:80.
* **Availability Zones:** Select both Public Subnets.
### 3. Configure Security Settings
* **Security Group:** Select `ALB-SG`.
### 4. Configure Routing
* **Target Group:** Select `Django-App-TG`.

## Phase 5: Compute & Deployment
### 1. Launch EC2 Instances
* **Quantity:** 2 Instances.
* **Subnet:** `Private-App-1` and `Private-App-2`.
* **IAM Role:** Attach `LabProfileRole` from advance setting while creating EC2.
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
# Update the DB_HOST with your RDS endpoint
DB_HOST=database-1.c4harpvynqqh.us-east-1.rds.amazonaws.com
DB_NAME=ecommerce
DB_USER=admin
DB_PORT=3306
DB_PASSWORD=mauFJcuf5dhRMQrjj
ALLOWED_HOSTS=*
# put server number 1 or 2 based on the instance
SERVER_NUMBER=[server number]
# Update with your S3 bucket name
AWS_STORAGE_BUCKET_NAME=djangomedia[studentname]
EOF

# 8. FIX PERMISSIONS BEFORE RUNNING DOCKER
# Ensure ec2-user owns everything
chown -R ec2-user:ec2-user /home/ec2-user/app

# 9. RUN DOCKER AS ROOT (Since User Data runs as root)
# We don't need to wait for a logout/login this way
docker compose build
docker compose up -d

echo "Deployment Complete!"

```

## Step 6: Add EC2 to Target Group
1.  Go to the Target Group `Django-App-TG`.
2.  Click on the **Targets** tab → **Edit**.
3.  Select both EC2 instances and add to the target group.
## Step 7: Test the Application
1.  Get the DNS name of the ALB from the EC2 Console.
2.  Open a browser and navigate to the ALB DNS.
3.  You should see the Django application running!