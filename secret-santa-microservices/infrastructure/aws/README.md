# AWS Infrastructure for Secret Santa Microservices

This directory contains the Terraform configuration for AWS SQS + SNS message broker infrastructure.

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   API Gateway   │───▶│   SNS Topic      │───▶│  CSV Parser     │
│   (Rails)       │    │   (Fan-out)      │    │  Service (Go)   │
│   Port: 3000    │    │                  │    │  Port: 8080     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       │
         │              ┌─────────────────┐              │
         └──────────────│  Assignment     │◀─────────────┘
                        │  Service (Rails)│
                        │  Port: 3001     │
                        └─────────────────┘
```

## 📋 Resources Created

### SNS Topics
- `secret-santa-employee-data-raw` - Raw CSV data from API Gateway
- `secret-santa-employee-data-parsed` - Parsed employee data from CSV Service
- `secret-santa-assignments-requested` - Assignment requests
- `secret-santa-assignments-generated` - Generated assignments

### SQS Queues
- `secret-santa-csv-parser-queue` - Queue for CSV Parser Service
- `secret-santa-assignment-service-queue` - Queue for Assignment Service
- Dead Letter Queues (DLQ) for failed message handling

### IAM Resources
- Service role for ECS tasks
- SQS/SNS access policies

## 🚀 Deployment

### Prerequisites
1. AWS CLI configured
2. Terraform installed
3. Appropriate AWS permissions

### Commands
```bash
# Initialize Terraform
cd infrastructure/aws
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply

# Destroy resources (when done)
terraform destroy
```

## 💰 Cost Estimation

### Monthly Costs (us-east-1)
- **SNS**: ~$0.50 per million requests
- **SQS**: ~$0.40 per million requests
- **IAM**: Free
- **Total**: ~$1-5/month for typical usage

## 🔧 Configuration

### Variables
- `aws_region`: AWS region (default: us-east-1)
- `environment`: Environment name (default: dev)
- `project_name`: Project name for tagging (default: secret-santa)

### Environment Variables
Set these in your services:
```bash
AWS_REGION=us-east-1
SNS_TOPIC_EMPLOYEE_DATA_RAW=arn:aws:sns:...
SNS_TOPIC_EMPLOYEE_DATA_PARSED=arn:aws:sns:...
SQS_QUEUE_CSV_PARSER=https://sqs.us-east-1.amazonaws.com/...
SQS_QUEUE_ASSIGNMENT_SERVICE=https://sqs.us-east-1.amazonaws.com/...
```

## 📊 Monitoring

### CloudWatch Metrics
- SNS message delivery success/failure
- SQS queue depth and processing time
- Dead letter queue message count

### Alerts
- Queue depth > 100 messages
- DLQ message count > 10
- SNS delivery failure rate > 5%

## 🔒 Security

### IAM Permissions
- Least privilege access
- Service-specific policies
- ECS task role integration

### Network Security
- VPC isolation (when deployed with ECS)
- Security groups for service communication
- Encryption in transit and at rest

## 🧪 Testing

### Local Testing
```bash
# Test SNS publishing
aws sns publish --topic-arn $SNS_TOPIC_ARN --message "test message"

# Test SQS message receiving
aws sqs receive-message --queue-url $SQS_QUEUE_URL
```

### Integration Testing
- Mock AWS services for unit tests
- Use LocalStack for local development
- Test message flow end-to-end
