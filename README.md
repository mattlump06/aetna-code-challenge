# Self-Service Cloud Platform - Core Challenge

This project provides a self-service platform for deploying containerized applications to AWS ECS Fargate using Terraform and GitHub Actions. Developers can deploy infrastructure and applications through a simple GitHub Actions workflow with input parameters.

## Architecture

The solution consists of:
- **ECS Fargate**: Containerized workload running in a fully managed VPC
- **ECR Repository**: Amazon Elastic Container Registry for storing Docker images with image scanning and lifecycle policies
- **Application Load Balancer**: Public-facing load balancer for service access
- **S3 Bucket**: Secure storage bucket with encryption and versioning enabled
- **CloudWatch Alarms**: Monitoring for CPU utilization and error logs with email notifications

## Prerequisites

- AWS Account with appropriate permissions
- GitHub repository
- AWS credentials configured (via GitHub Secrets or IAM Role)
- Terraform >= 1.6.0
- Docker (for local testing)

## Local Development

### Building and Running the Container Locally

1. **Build the Docker image:**
   ```bash
   cd app
   docker build -t hello-world-app .
   ```

2. **Run the container locally:**
   ```bash
   docker run -d -p 8080:80 --name hello-world hello-world-app
   ```

3. **Test the service:**
   ```bash
   curl http://localhost:8080
   ```
   
   Or open `http://localhost:8080` in your browser. You should see a "Hello World!" page.

4. **Stop the container:**
   ```bash
   docker stop hello-world
   docker rm hello-world
   ```

### Container Details

- **Exposed Port**: 80
- **Health Check**: Configured with curl-based health check
- **Base Image**: nginx:alpine

## Deployment via GitHub Actions

### Setup

1. **Configure AWS Credentials:**
   - Set up GitHub Secrets or configure OIDC with AWS IAM Role
   - For OIDC, set `AWS_ROLE_ARN` in GitHub Secrets

2. **Configure Terraform Backend (Optional):**
   - Edit `terraform/main.tf` to configure S3 backend for state management
   - Or use local state for demo purposes

### Build and Push Docker Image

Before deploying infrastructure, you should build your Docker image and push it to ECR:

1. **Build Image via GitHub Actions:**
   - Go to GitHub Actions tab in your repository
   - Select **"Build and Push Docker Image"** workflow
   - Click **"Run workflow"**
   - Fill in the required inputs:
     - **app_name**: Name of your application (e.g., "hello-world")
     - **environment**: Environment name (dev/staging/prod)
     - **aws_region**: AWS region (default: us-east-1)
     - **image_tag**: Optional custom tag (defaults to commit SHA)
   - Click **"Run workflow"**

2. **Get the ECR Image URI:**
   - After the workflow completes, check the workflow output for the image URI
   - Format: `{account-id}.dkr.ecr.{region}.amazonaws.com/{app_name}-{environment}-app:{tag}`
   - Or use `latest` tag: `{account-id}.dkr.ecr.{region}.amazonaws.com/{app_name}-{environment}-app:latest`

**Note:** The workflow automatically creates the ECR repository if it doesn't exist (though it's recommended to deploy infrastructure first via Terraform, which creates the ECR repository with proper configuration).

**Alternative:** You can also build locally and push manually:
```bash
# Authenticate with ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin {account-id}.dkr.ecr.us-east-1.amazonaws.com

# Build and tag
cd app
docker build -t {account-id}.dkr.ecr.us-east-1.amazonaws.com/{app_name}-{environment}-app:latest .
docker push {account-id}.dkr.ecr.us-east-1.amazonaws.com/{app_name}-{environment}-app:latest
```

### Deploy Infrastructure

1. **Deploy Infrastructure:**
   - Go to GitHub Actions tab in your repository
   - Select "Deploy Infrastructure" workflow
   - Click "Run workflow"
   - Fill in the required inputs:
     - **app_name**: Name of your application (e.g., "hello-world")
     - **environment**: Environment name (dev/staging/prod)
     - **container_image**: Docker image URL from ECR (e.g., `{account-id}.dkr.ecr.us-east-1.amazonaws.com/hello-world-dev-app:latest`)
     - **container_port**: Port your container exposes (default: 80)
     - **cpu**: CPU units (256, 512, 1024, etc.)
     - **memory**: Memory in MB (512, 1024, 2048, etc.)
     - **desired_count**: Number of tasks to run (default: 1)
     - **alert_email**: Email for CloudWatch alerts
     - **aws_region**: AWS region (default: us-east-1)

**Note:** When you deploy infrastructure, an ECR repository is automatically created with the name `{app_name}-{environment}-app`. You can use the ECR repository URL from Terraform outputs to get the exact image URI.

### Example Workflow Inputs

**Build Image:**
```
app_name: hello-world
environment: dev
aws_region: us-east-1
image_tag: v1.0.0  # Optional
```

**Deploy Infrastructure:**
```
app_name: hello-world
environment: dev
container_image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/hello-world-dev-app:latest
container_port: 80
cpu: 256
memory: 512
desired_count: 1
alert_email: your-email@example.com
aws_region: us-east-1
```

## Manual Terraform Deployment

If you prefer to deploy manually:

1. **Navigate to terraform directory:**
   ```bash
   cd terraform
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan deployment:**
   ```bash
   terraform plan \
     -var="app_name=hello-world" \
     -var="environment=dev" \
     -var="container_image=nginx:latest" \
     -var="container_port=80" \
     -var="cpu=256" \
     -var="memory=512" \
     -var="desired_count=1" \
     -var="alert_email=your-email@example.com" \
     -var="aws_region=us-east-1"
   ```

4. **Apply changes:**
   ```bash
   terraform apply
   ```

5. **Get outputs:**
   ```bash
   terraform output service_url
   terraform output s3_bucket_name
   terraform output ecr_repository_url
   ```

   The `ecr_repository_url` output shows the ECR repository where you should push your Docker images.

## Terraform Modules

The infrastructure is organized into reusable modules:

- **modules/ecs**: ECS Fargate cluster, service, VPC, ALB, ECR repository, and networking
- **modules/s3**: S3 bucket with encryption, versioning, and public access blocking
- **modules/cloudwatch**: CloudWatch alarms for CPU and error logs with SNS notifications

### ECR Repository

The ECS module automatically creates an ECR repository with:
- Image scanning enabled on push
- AES256 encryption
- Lifecycle policy to keep the last 10 images
- Repository name: `{app_name}-{environment}-app`

## Testing

Run Terraform tests:

```bash
cd terraform
terraform test
```

Tests verify:
- S3 bucket encryption is enabled
- S3 bucket versioning is enabled
- S3 bucket public access is blocked
- CloudWatch alarms are created

## Accessing Your Application

After deployment, get the service URL:

```bash
terraform output service_url
```

Or find it in the GitHub Actions workflow output. The service will be accessible via HTTP on port 80 through the Application Load Balancer.

## Updating Infrastructure

### Build and Deploy New Image Version

To deploy a new version of your application:

1. **Build and push new image:**
   - Go to GitHub Actions → **"Build and Push Docker Image"**
   - Run the workflow with your app_name and environment
   - The workflow will build and push the image with a new tag (commit SHA or custom tag)

2. **Update infrastructure with new image:**
   - Go to GitHub Actions → **"Update Infrastructure"**
   - Fill in the inputs:
     - **app_name**: Must match the app name used during deployment
     - **environment**: Must match the environment used during deployment (dev/staging/prod)
     - **container_image**: New ECR image URL (e.g., `{account-id}.dkr.ecr.us-east-1.amazonaws.com/hello-world-dev-app:{new-tag}`)
     - **aws_region**: AWS region (default: us-east-1)
   - Click **Run workflow**

The workflow will:
- Read existing configuration values from Terraform state (CPU, memory, container port, etc.)
- Update only the container image
- Deploy the new image to ECS (ECS will automatically perform a rolling update)

**Note:** The workflow automatically preserves existing values (CPU, memory, desired count, etc.) from your current deployment. Only the container image will be updated.

### Quick Update Workflow

For a complete CI/CD flow:
1. Push code changes to `app/` directory → Build workflow triggers automatically
2. Build workflow creates image with commit SHA tag
3. Use the image URI from build workflow output in the Update Infrastructure workflow

### Manual Update

To update manually, modify the variables and re-apply:

```bash
cd terraform
terraform plan -var="container_image=nginx:1.25" ...  # other vars
terraform apply
```

## CloudWatch Alarms

Two alarms are configured:

1. **CPU Utilization**: Triggers when ECS service CPU exceeds 80% for 2 consecutive periods (5 minutes each)
2. **Error Logs**: Triggers when more than 10 "ERROR" log entries are written in a minute

You'll receive email notifications at the address specified in `alert_email`. **Note**: You must confirm the SNS subscription via the email sent to your address.

## Cleanup

### Manual Terraform Destroy

To destroy all resources manually:

```bash
cd terraform
terraform destroy
```

### GitHub Actions Destroy Workflow

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. Select **Destroy Infrastructure** in the left sidebar
4. Click **Run workflow** (top right)
5. Fill in the inputs:
   - **app_name**: Must match the app name used during deployment
   - **environment**: Must match the environment used during deployment (dev/staging/prod)
   - **aws_region**: AWS region (default: us-east-1)
   - **confirmation**: Type exactly `destroy` to confirm deletion
6. Click **Run workflow**

**⚠️ Warning:** This will permanently delete all infrastructure resources including:
- ECS cluster, services, and tasks
- ECR repository and all Docker images
- VPC, subnets, NAT Gateway, and networking components
- Application Load Balancer
- S3 bucket and all its contents
- CloudWatch alarms and log groups
- SNS topics and subscriptions

Make sure you have backups of any important data before destroying.

## Architecture Diagram

See the `diagrams/` directory for architectural diagrams and CI/CD workflow charts.

## Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── build-image.yml     # Build and push Docker image to ECR
│       └── deploy.yml          # GitHub Actions deployment workflow
├── app/
│   ├── Dockerfile              # Container definition
│   ├── index.html              # Simple web page
│   └── .dockerignore
├── terraform/
│   ├── main.tf                 # Root module
│   ├── variables.tf            # Root variables
│   ├── modules/
│   │   ├── ecs/                # ECS module (includes ECR repository)
│   │   ├── s3/                 # S3 module
│   │   └── cloudwatch/         # CloudWatch module
│   └── tests/                  # Terraform tests
├── diagrams/                   # Architecture diagrams
└── README.md                   # This file
```

## Security Features

- S3 bucket encryption at rest (AES256)
- S3 bucket public access blocked
- ECR repository encryption (AES256)
- ECR image scanning on push
- VPC with private subnets for ECS tasks
- Security groups restricting access
- IAM roles with least privilege

## Cost Considerations

This setup uses:
- ECS Fargate: Pay per vCPU and memory used
- ECR: Pay per GB stored and per GB transferred
- Application Load Balancer: ~$16/month
- NAT Gateway: ~$32/month + data transfer
- CloudWatch Logs: Based on log volume
- S3: Minimal cost usage


## Next Steps

- Add HTTPS/SSL with ACM certificate
- Implement blue/green deployments
- Add autoscaling policies
- Configure custom domain names
- Add automated testing to build workflow
- Set up image vulnerability scanning alerts

