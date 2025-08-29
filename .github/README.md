# CI/CD Pipeline Documentation

## Overview

This repository uses GitHub Actions for continuous integration and deployment (CI/CD) with comprehensive monitoring and alerting.

## Workflows

### 1. CI Pipeline (`.github/workflows/ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` branch

**Jobs:**
- **Test CSV Parser Service**: Runs Go tests and builds the service
- **Test Assignment Service**: Runs RSpec tests with PostgreSQL
- **Test API Gateway**: Runs RSpec tests with PostgreSQL
- **Security Scan**: Runs Trivy vulnerability scanner
- **Terraform Validation**: Validates and plans infrastructure changes

### 2. CD Pipeline (`.github/workflows/cd.yml`)

**Triggers:**
- Push to `main` branch
- Manual dispatch

**Jobs:**
- **Build and Push Images**: Builds and pushes Docker images to ECR
- **Deploy Infrastructure**: Applies Terraform changes and updates ECS services
- **Health Check**: Verifies deployment success

### 3. Monitoring (`.github/workflows/monitoring.yml`)

**Triggers:**
- Every 5 minutes (scheduled)
- Manual dispatch

**Jobs:**
- **CloudWatch Metrics Check**: Monitors service health and performance
- **Alert on Failure**: Sends notifications on failures

## Required Secrets

Configure these secrets in your GitHub repository settings:

```bash
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_ACCOUNT_ID=your_aws_account_id
SLACK_WEBHOOK_URL=your_slack_webhook_url (optional)
```

## Infrastructure Monitoring

### CloudWatch Dashboard
- ECS CPU and Memory utilization
- ALB request metrics and response times
- SQS queue metrics
- Error rates and performance indicators

### CloudWatch Alarms
- API Gateway 5XX errors (>10 in 5 minutes)
- ECS CPU utilization (>80%)
- SQS queue depth (>100 messages)
- Email notifications via SNS

### Log Groups
- `/ecs/secret-santa-csv-parser`
- `/ecs/secret-santa-assignment-service`
- `/ecs/secret-santa-api-gateway`

## Deployment Process

1. **Code Push**: Triggers CI pipeline
2. **Testing**: All services are tested
3. **Security Scan**: Vulnerability assessment
4. **Infrastructure Validation**: Terraform plan
5. **Image Building**: Docker images built and pushed to ECR
6. **Deployment**: Infrastructure applied and ECS services updated
7. **Health Check**: Verification of deployment success
8. **Monitoring**: Continuous monitoring and alerting

## Local Development

For local development, use the provided scripts:

```bash
# Start local development environment
./start_local_dev.sh

# Stop local development environment
./stop_local_dev.sh
```

## Troubleshooting

### Common Issues

1. **ECS Service Not Starting**
   - Check CloudWatch logs
   - Verify task definition and container health checks
   - Check IAM roles and permissions

2. **ALB Health Check Failing**
   - Verify service is running on correct port
   - Check security group rules
   - Verify health check path exists

3. **SQS Messages Not Processing**
   - Check service logs for errors
   - Verify IAM permissions for SQS/SNS
   - Check queue visibility timeout settings

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster secret-santa-cluster --services secret-santa-api-gateway

# View CloudWatch logs
aws logs tail /ecs/secret-santa-api-gateway --follow

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Monitor SQS queue
aws sqs get-queue-attributes --queue-url <queue-url> --attribute-names All
```
