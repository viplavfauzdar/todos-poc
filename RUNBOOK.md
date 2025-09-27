# Runbook: Todos POC

This runbook documents the operational steps for building, deploying, testing, and rolling back the **Todos POC** Spring Boot application on AWS.

---

## 1. Build

### Local build
```bash
./gradlew clean build
```

### Docker build
```bash
docker buildx build --platform linux/amd64 -t todos-poc:latest .
```

### Lambda container build
```bash
docker buildx build --platform linux/amd64 -f Dockerfile.lambda -t todos-lambda:latest .
```

---

## 2. Push to ECR

```bash
REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Create repos if not exist
aws ecr create-repository --repository-name todos-poc || true
aws ecr create-repository --repository-name todos-lambda || true

# Login
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR

# Tag & push
docker tag todos-poc:latest $ECR/todos-poc:latest
docker push $ECR/todos-poc:latest

docker tag todos-lambda:latest $ECR/todos-lambda:latest
docker push $ECR/todos-lambda:latest
```

---

## 3. Deploy

Choose the target platform. Terraform configs are under `infra/`.

### App Runner
```bash
cd infra/apprunner
terraform init
terraform apply -var="region=us-east-1" \
  -var="image_identifier=$ECR/todos-poc:latest" \
  -auto-approve
```

### ECS Fargate + ALB
```bash
cd infra/ecs-fargate-alb
terraform init
terraform apply -var="region=us-east-1" \
  -var="image=$ECR/todos-poc:latest" \
  -auto-approve
```

### Lambda (Container Image)
```bash
cd infra/lambda-container
terraform init
terraform apply -var="region=us-east-1" \
  -var="image_uri=$ECR/todos-lambda:latest" \
  -auto-approve
```

---

## 4. Smoke Tests

Replace `$URL` with service URL (App Runner, ALB DNS, or Lambda Function URL).

```bash
# Health
curl -s $URL/actuator/health

# List (empty at start)
curl -s $URL/api/todos

# Create
curl -s -X POST $URL/api/todos \
  -H 'Content-Type: application/json' \
  -d '{"title":"smoke test"}'

# Verify
curl -s $URL/api/todos
```

---

## 5. Rollback

- **App Runner:**  
  - Re-deploy older tag in ECR  
  - Or use "Revert deployment" in console

- **ECS Fargate:**  
  - Update service with previous task definition revision  
  - Or update image tag to known-good version

- **Lambda:**  
  - Update function code with older image tag  
  - Or point function alias back to previous version

---

## 6. Logs & Monitoring

- **App Runner:** CloudWatch logs group `/aws/apprunner/<service-id>`
- **ECS Fargate:** CloudWatch logs group `/ecs/<cluster>/<service>`
- **Lambda:** CloudWatch logs group `/aws/lambda/<function-name>`

Monitor health:
- ALB Target Group status
- App Runner health check
- Lambda CloudWatch metrics (`Duration`, `Errors`, `Throttles`)

---

## 7. Notes

- Always build with `--platform linux/amd64` from Apple Silicon to match AWS runtimes.
- Keep image tags immutable for reliable rollbacks (e.g., `:20250927-1`).
- For production, use private VPC + RDS instead of in-memory store.