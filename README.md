# Hello Web App - AWS Deployment Guide

This guide provides step-by-step instructions for deploying the Go web application to AWS using Jenkins CI/CD, Terraform for infrastructure provisioning, and Ansible for configuration management.

## Prerequisites

### 1. AWS Setup
- **AWS Account**: Create an AWS account or use an existing one
- **AWS CLI**: Install and configure AWS CLI locally
  ```bash
  aws configure
  ```
- **EC2 Key Pair**: Create a key pair for SSH access
  ```bash
  aws ec2 create-key-pair --key-name my-keypair --query 'KeyMaterial' --output text > my-keypair.pem
  chmod 400 my-keypair.pem
  ```

### 2. Jenkins Setup
- **Jenkins Server**: Running Jenkins instance (local Docker or AWS EC2)
- **Required Plugins**: Install these Jenkins plugins:
  - Terraform Plugin
  - Ansible Plugin
  - Docker Pipeline Plugin
  - SonarQube Scanner Plugin
- **Go Tool**: Install Go tool in Jenkins Global Tool Configuration

### 3. Credentials Setup in Jenkins
Add these credentials in Jenkins (Manage Jenkins → Credentials):

#### AWS Credentials
- **ID**: `AWS_ACCESS_KEY_ID`
- **Secret**: Your AWS Access Key ID
- **ID**: `AWS_SECRET_ACCESS_KEY`
- **Secret**: Your AWS Secret Access Key

#### Docker Hub Credentials
- **ID**: `DOCKER_REGISTRY_CREDENTIALS_ID`
- **Username**: Your Docker Hub username
- **Password**: Your Docker Hub password/token

#### SonarQube Token
- **ID**: `SONAR_TOKEN`
- **Secret**: Your SonarQube Cloud token

## Configuration Files Overview

### Terraform Files
- `main.tf`: AWS infrastructure configuration (VPC, EC2, Security Groups)
- `variables.tf`: Terraform variables

### Ansible Files
- `ansible/deploy-aws.yaml`: AWS deployment playbook
- `ansible/inventory.ini`: Ansible inventory for AWS servers

### Jenkins Files
- `Jenkinsfile`: Complete CI/CD pipeline for AWS deployment

## Step-by-Step Deployment

### Step 1: Prepare Your Environment

1. **Clone the repository** (if not already done):
   ```bash
   git clone https://github.com/ntttrang/hello-webapp-golang.git
   cd hello-webapp-golang
   ```

2. **Configure Terraform variables** (optional):
   Edit `variables.tf` to customize:
   - AWS region (default: us-east-1)
   - Instance type (default: t2.micro)
   - Key pair name (default: my-keypair)

3. **Update Ansible inventory template**:
   The inventory file is configured to be updated automatically by Jenkins, but you can manually set it:
   ```bash
   # Edit ansible/inventory.ini
   # Replace YOUR_EC2_PUBLIC_IP with your actual EC2 IP later
   ```

### Step 2: Jenkins Pipeline Configuration

1. **Create a new Jenkins Pipeline job**:
   - Go to Jenkins Dashboard → New Item
   - Select "Pipeline"
   - Enter job name: "hello-webapp-aws-deployment"

2. **Configure the Pipeline**:
   - **Pipeline Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/ntttrang/hello-webapp-golang.git`
   - **Branch Specifier**: `*/master`
   - **Script Path**: `Jenkinsfile`

3. **Add Parameters** (optional):
   - **GIT_TAG**: String parameter for branch/tag selection
   - Default value: `master`

### Step 3: Execute the Deployment

1. **Trigger the Pipeline**:
   - Click "Build Now" on the Jenkins job
   - Or use "Build with Parameters" to specify a different branch/tag

2. **Monitor the Pipeline Stages**:
   - **Checkout source code**: Clones the repository
   - **Unit Test**: Runs Go tests
   - **Coverage Report**: Generates test coverage
   - **Run SonarQube Analysis**: Code quality analysis
   - **Build**: Compiles the Go application
   - **Build Docker Image**: Creates Docker image
   - **Push Docker Image**: Pushes to Docker Hub
   - **Terraform Apply**: Provisions AWS infrastructure
   - **Update Ansible Inventory**: Updates inventory with EC2 IP
   - **Run Ansible Playbook**: Deploys to AWS

### Step 4: Access Your Application

After successful deployment:

1. **Get the application URL**:
   - Check Jenkins console output for the public IP
   - Or use AWS Console to find your EC2 instance public IP

2. **Access the application**:
   ```
   http://<EC2_PUBLIC_IP>:8080
   ```

3. **Verify deployment**:
   - You should see "Hello, World!" message
   - Check Jenkins logs for deployment status

## Infrastructure Details

### AWS Resources Created
- **VPC**: Custom VPC with public subnet
- **EC2 Instance**: t2.micro with Amazon Linux 2
- **Security Group**: Allows SSH (22) and HTTP (8080)
- **Internet Gateway**: For internet access
- **Route Table**: Public routing configuration

### Application Architecture
- **Docker Container**: Go application running in Docker
- **Port Mapping**: Host port 8080 → Container port 8080
- **Auto-restart**: Container restarts automatically on failure

## Troubleshooting

### Common Issues

1. **Terraform Errors**:
   - Check AWS credentials in Jenkins
   - Verify key pair exists in AWS
   - Ensure AWS region has available resources

2. **Ansible Connection Errors**:
   - Verify EC2 instance is running
   - Check security group allows SSH from Jenkins
   - Ensure key pair permissions are correct (chmod 400)

3. **Docker Deployment Errors**:
   - Check Docker Hub credentials
   - Verify Docker service is running on EC2
   - Check container logs: `docker logs helloapp`

### Fundamental Concepts (For Newbies)

#### 1. AWS Access Keys vs EC2 Key Pairs

**Why do we need both AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY AND EC2 Key Pairs?**

These serve completely different purposes:

**AWS Access Keys (AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY):**
- **Purpose**: Authenticate API calls to AWS services
- **Used by**: Terraform, AWS CLI, SDKs
- **Scope**: Global AWS account access
- **Example usage**:
  ```bash
  # Terraform uses these to create EC2 instances
  terraform apply

  # AWS CLI uses these for any AWS operations
  aws ec2 describe-instances
  ```

**EC2 Key Pairs:**
- **Purpose**: SSH access to individual EC2 instances
- **Used by**: SSH clients (you, Ansible, scripts)
- **Scope**: Specific EC2 instance only
- **Example usage**:
  ```bash
  # You use this to SSH into your server
  ssh -i my-keypair.pem ec2-user@54.123.456.789

  # Ansible uses this to connect and deploy
  ansible-playbook -i inventory.ini deploy.yaml
  ```

**Simple Analogy:**
- AWS Access Keys = **Credit Card** (for making purchases/API calls)
- EC2 Key Pair = **House Key** (for entering specific server)

**Without AWS Access Keys:** ❌ Can't create any AWS resources
**Without EC2 Key Pair:** ❌ Can't access or deploy to your servers

#### 2. Ansible Inventory File (inventory.ini)

**What is inventory.ini and why do we need it?**

**inventory.ini** = **Address Book for Your Servers**

Just like you need a friend's phone number to call them, Ansible needs server addresses to deploy to them.

**Why We Need Inventory:**
```bash
# ❌ Without inventory - Ansible doesn't know where to go
ansible-playbook ansible/deploy-aws.yaml  # ERROR: No target specified

# ✅ With inventory - Ansible knows exactly where to deploy
ansible-playbook -i ansible/inventory.ini ansible/deploy-aws.yaml
```

**How It Works:**
1. **Template State** (before deployment):
   ```ini
   [aws_servers]
   # aws-server ansible_host=YOUR_EC2_PUBLIC_IP ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/your-keypair.pem
   ```

2. **Jenkins Updates It** (during deployment):
   ```bash
   # Gets actual IP from Terraform
   INSTANCE_IP=$(terraform output -raw instance_public_ip)

   # Updates inventory with real IP
   sed -i "s|YOUR_EC2_PUBLIC_IP|54.123.456.789|g" ansible/inventory.ini
   ```

3. **Final State** (after update):
   ```ini
   [aws_servers]
   aws-server ansible_host=54.123.456.789 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/your-keypair.pem
   ```

**What Each Part Means:**
- `[aws_servers]` = **Group name** (like "webservers", "databases")
- `aws-server` = **Server name** (you can choose any name)
- `ansible_host=54.123.456.789` = **Server's IP address**
- `ansible_user=ec2-user` = **SSH username**
- `ansible_ssh_private_key_file=~/.ssh/your-keypair.pem` = **Path to SSH key**

**Why Dynamic Updates?**
- AWS assigns **random public IPs** each time you create EC2 instances
- You can't know the IP beforehand
- Jenkins automatically updates inventory with the actual IP from Terraform

**Simple Analogy:**
```
Phone Book (inventory.ini):    Reality:
- John: 555-0123               - John: 555-0123 (known number)
- Server1: ???                  - Server1: 54.123.456.789 (AWS gives random IP)

Ansible needs the phone book to know "who to call and at what number"
```

**Common Newbie Confusion:**
*"I have the IP address, why do I need a file?"*

**Answer:** Because Ansible reads from files, not from your memory. The inventory file is Ansible's way of knowing "which servers exist and how to reach them."

### Useful Commands

**Check Terraform state**:
```bash
terraform show
```

**SSH into EC2 instance**:
```bash
ssh -i my-keypair.pem ec2-user@<EC2_PUBLIC_IP>
```

**Check Docker containers on EC2**:
```bash
docker ps -a
docker logs helloapp
```

**Destroy infrastructure** (when needed):
```bash
terraform destroy -auto-approve
```

## Security Considerations

1. **Key Pair Security**: Keep your private key secure and don't commit it to version control
2. **Security Groups**: The current setup allows SSH from anywhere (0.0.0.0/0). Consider restricting to specific IPs
3. **Credentials**: Use Jenkins credentials store for sensitive information
4. **Network Security**: Consider using private subnets for production deployments

## Cost Optimization

- **Instance Type**: t2.micro is free tier eligible
- **Resource Cleanup**: Remember to destroy resources when not needed
- **Monitoring**: Set up CloudWatch for monitoring costs and performance

## Next Steps

1. **Domain Name**: Add Route 53 for custom domain
2. **Load Balancer**: Add ELB for high availability
3. **Database**: Add RDS if your app needs a database
4. **Monitoring**: Add CloudWatch monitoring and alerts
5. **SSL Certificate**: Add HTTPS with AWS Certificate Manager

---

For issues or questions, check the Jenkins logs and AWS CloudWatch logs for detailed error information.
