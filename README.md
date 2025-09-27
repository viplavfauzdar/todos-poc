# todos-poc\nMinimal Spring Boot TODOs API for App Runner, ECS Fargate, Lambda.\nSee RUNBOOK.md.\n
# Todos POC

A minimal **Spring Boot 3** TODOs API designed to demonstrate deployment on multiple AWS compute platforms:

- [AWS App Runner](https://docs.aws.amazon.com/apprunner/)
- [Amazon ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html) with Application Load Balancer
- [AWS Lambda](https://docs.aws.amazon.com/lambda/) with container image + Function URL

This repo includes:
- Spring Boot REST API (`/api/todos`) with in-memory store
- Gradle build (Java 21 toolchain)
- Dockerfile for App Runner / ECS
- Dockerfile.lambda for AWS Lambda
- Terraform modules for App Runner, ECS Fargate + ALB, and Lambda container
- GitHub Actions workflow scaffold
- [RUNBOOK.md](RUNBOOK.md) with deploy, smoke tests, and rollback steps

---

## Features

- Create, list, update, and delete todos
- In-memory store (no external DB required for POC)
- Spring Boot Actuator endpoints (`/actuator/health`)
- OpenAPI UI at `/swagger-ui.html`

---

## Local Development

### Prerequisites
- Java 21 (Temurin or Corretto)
- Gradle (wrapper included)
- Docker (for container builds)

### Run locally
```bash
./gradlew bootRun
```
Visit: [http://localhost:8080/api/todos](http://localhost:8080/api/todos)

---

## Build and Run with Docker

### Build image
```bash
docker buildx build --platform linux/amd64 -t todos-poc:latest .
```

### Run container
```bash
docker run -p 8080:8080 todos-poc:latest
```

---

## Deploy Options

This project supports three AWS deployment options. See `infra/` directory for Terraform templates.

### 1. App Runner
- Push image to ECR
- Apply Terraform in `infra/apprunner`
- Outputs: App Runner service URL

### 2. ECS Fargate + ALB
- Push image to ECR
- Apply Terraform in `infra/ecs-fargate-alb`
- Creates ALB, Target Group, ECS Cluster, Service
- Outputs: ALB DNS to access the app

### 3. Lambda (Container Image)
- Build with `Dockerfile.lambda`
- Push image to ECR
- Apply Terraform in `infra/lambda-container`
- Outputs: Lambda Function URL

---

## API Examples

```bash
# Health check
curl http://localhost:8080/actuator/health

# List todos
curl http://localhost:8080/api/todos

# Create a todo
curl -X POST http://localhost:8080/api/todos \
  -H 'Content-Type: application/json' \
  -d '{"title":"first task"}'

# Update a todo
curl -X PUT http://localhost:8080/api/todos/1 \
  -H 'Content-Type: application/json' \
  -d '{"title":"updated","done":true}'

# Delete a todo
curl -X DELETE http://localhost:8080/api/todos/1
```

---

## Observability

- Actuator metrics at `/actuator/prometheus` (if you add micrometer dependency)
- Health endpoint used by ALB/App Runner
- Logs go to:
  - CloudWatch (Lambda, ECS)
  - App Runner service logs

---

## Repository Layout

```
todos-poc/
├── src/main/java/com/example/todos/       # Spring Boot app code
├── src/main/resources/                    # application.yml
├── Dockerfile                             # App Runner/ECS
├── Dockerfile.lambda                      # Lambda
├── infra/
│   ├── apprunner/                         # Terraform for App Runner
│   ├── ecs-fargate-alb/                   # Terraform for ECS Fargate + ALB
│   └── lambda-container/                  # Terraform for Lambda container
├── .github/workflows/                     # GitHub Actions CI/CD scaffold
├── RUNBOOK.md                             # Deployment runbook
└── README.md
```

---

## Next Steps

- Extend to use RDS (Postgres) instead of in-memory store
- Add authentication (Cognito / OAuth2)
- Wire metrics to CloudWatch / Prometheus
- Use GitHub Actions for automated build & deploy

---

## License

MIT