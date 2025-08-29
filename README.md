# Secret Santa Microservices

A production-ready microservices architecture for Secret Santa assignment generation, built with Go and Ruby on Rails, deployed on AWS with comprehensive CI/CD and monitoring.

## 🏗️ Architecture Overview

This project implements a modern microservices architecture with the following components:

- **CSV Parser Service (Go)**: Handles CSV data parsing and validation
- **Assignment Service (Rails)**: Generates Secret Santa assignments with business logic
- **API Gateway (Rails)**: Orchestrates requests and provides unified API
- **AWS Infrastructure**: ECS, ECR, ALB, SQS, SNS, CloudWatch
- **CI/CD Pipeline**: GitHub Actions for automated testing and deployment

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Go 1.21+
- Ruby 3.3+
- AWS CLI (for production deployment)
- Terraform (for infrastructure)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd secret-santa-microservices
   ```

2. **Start local development environment**
   ```bash
   ./start_local_dev.sh
   ```

3. **Test the API**
   ```bash
   # Health check
   curl http://localhost:3000/api/v1/secret_santa/health
   
   # Generate assignments
   curl -X POST http://localhost:3000/api/v1/secret_santa/generate_assignments \
     -H "Content-Type: application/json" \
     -d '{
       "employees": [
         {"name": "John Doe", "email": "john@example.com"},
         {"name": "Jane Smith", "email": "jane@example.com"},
         {"name": "Bob Johnson", "email": "bob@example.com"}
       ]
     }'
   ```

4. **Stop local development**
   ```bash
   ./stop_local_dev.sh
   ```

## 📁 Project Structure

```
secret-santa-microservices/
├── csv-parser-service/          # Go CSV parsing service
│   ├── internal/csvparser/     # Core parsing logic
│   ├── main.go                 # HTTP server and SQS/SNS integration
│   ├── Dockerfile              # Container configuration
│   └── go.mod                  # Go dependencies
├── assignment-service/          # Rails assignment generation service
│   ├── app/services/           # Business logic
│   ├── app/controllers/        # API endpoints
│   ├── app/jobs/               # Background job processing
│   ├── spec/                   # RSpec tests
│   ├── Dockerfile              # Container configuration
│   └── Gemfile                 # Ruby dependencies
├── api-gateway/                # Rails API gateway
│   ├── app/controllers/        # API orchestration
│   ├── spec/                   # RSpec tests
│   ├── Dockerfile              # Container configuration
│   └── Gemfile                 # Ruby dependencies
├── infrastructure/aws/         # Terraform infrastructure
│   ├── main.tf                 # Core AWS resources
│   ├── vpc.tf                  # Networking configuration
│   ├── ecs.tf                  # Container orchestration
│   ├── alb.tf                  # Load balancer
│   ├── ecr.tf                  # Container registry
│   ├── monitoring.tf           # CloudWatch and alerts
│   └── variables.tf            # Terraform variables
├── .github/workflows/          # CI/CD pipelines
│   ├── ci.yml                  # Continuous integration
│   ├── cd.yml                  # Continuous deployment
│   └── monitoring.yml          # Health monitoring
├── docker-compose.yml          # Production orchestration
├── docker-compose.local.yml    # Local development
├── start_local_dev.sh          # Local development script
├── stop_local_dev.sh           # Local development cleanup
└── PROJECT_STATUS.md           # Detailed project status
```

## 🧪 Testing

### Run All Tests

```bash
# CSV Parser Service (Go)
cd csv-parser-service
go test -v ./...

# Assignment Service (Rails)
cd assignment-service
bundle exec rspec

# API Gateway (Rails)
cd api-gateway
bundle exec rspec
```

### Test Coverage

- **CSV Parser**: Unit tests for parsing logic and HTTP handlers
- **Assignment Service**: RSpec tests for business logic and API endpoints
- **API Gateway**: Integration tests for service orchestration
- **Infrastructure**: Terraform validation and planning

## 🚀 Production Deployment

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **GitHub Secrets** configured:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_ACCOUNT_ID`
   - `SLACK_WEBHOOK_URL` (optional)

### Deployment Process

1. **Push to main branch** - Triggers automated CI/CD pipeline
2. **CI Pipeline** - Runs tests, security scans, and infrastructure validation
3. **CD Pipeline** - Builds Docker images, deploys to AWS ECS
4. **Health Checks** - Verifies deployment success

### Infrastructure Components

- **ECS Fargate**: Container orchestration
- **ECR**: Docker image storage
- **ALB**: Application load balancer
- **SQS/SNS**: Message queuing and notifications
- **CloudWatch**: Monitoring and alerting
- **VPC**: Network isolation and security

## 📊 Monitoring and Observability

### CloudWatch Dashboard

Real-time monitoring of:
- ECS service health and performance
- ALB request metrics and response times
- SQS queue depths and processing rates
- Error rates and system performance

### Alerts

Automated notifications for:
- Service health issues
- High error rates (>10 5XX errors in 5 minutes)
- High CPU utilization (>80%)
- SQS queue backlogs (>100 messages)

### Logs

Centralized logging for all services:
- `/ecs/secret-santa-csv-parser`
- `/ecs/secret-santa-assignment-service`
- `/ecs/secret-santa-api-gateway`

## 🔧 Configuration

### Environment Variables

#### CSV Parser Service
```bash
AWS_REGION=us-east-1
SQS_QUEUE_CSV_PARSER=secret-santa-csv-parser
SNS_TOPIC_EMPLOYEE_DATA_PARSED=secret-santa-employee-data-parsed
DEV_MODE=true  # For local development
```

#### Assignment Service
```bash
RAILS_ENV=production
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
AWS_REGION=us-east-1
SQS_QUEUE_ASSIGNMENT_SERVICE=secret-santa-assignment-service
SNS_TOPIC_ASSIGNMENTS_GENERATED=secret-santa-assignments-generated
ENABLE_SQS_PROCESSOR=true
```

#### API Gateway
```bash
RAILS_ENV=production
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
AWS_REGION=us-east-1
SNS_TOPIC_EMPLOYEE_DATA_RAW=secret-santa-employee-data-raw
SQS_QUEUE_ASSIGNMENTS_COMPLETED=secret-santa-assignments-completed
```

## 🔒 Security Features

- **Non-root containers**: All services run as non-root users
- **IAM roles**: Least privilege access to AWS services
- **Security groups**: Network-level access control
- **VPC isolation**: Private subnets for services
- **Secrets management**: AWS Secrets Manager integration
- **Security scanning**: Trivy vulnerability scanning in CI

## 📈 Scalability

- **Auto-scaling**: ECS service auto-scaling based on CPU/memory
- **Load balancing**: ALB distributes traffic across multiple instances
- **Message queuing**: SQS handles asynchronous processing
- **Horizontal scaling**: Stateless services can scale horizontally

## 🛠️ Development Workflow

### Local Development

1. **Start services**: `./start_local_dev.sh`
2. **Make changes**: Edit code in your preferred IDE
3. **Run tests**: Execute test suites for affected services
4. **Test locally**: Use curl or Postman to test APIs
5. **Stop services**: `./stop_local_dev.sh`

### Production Deployment

1. **Create feature branch**: `git checkout -b feature/new-feature`
2. **Make changes**: Implement new functionality
3. **Write tests**: Add comprehensive test coverage
4. **Commit changes**: Follow conventional commit messages
5. **Push and test**: CI pipeline validates changes
6. **Merge to main**: CD pipeline deploys to production

## 🐛 Troubleshooting

### Common Issues

#### Local Development
- **Port conflicts**: Check if ports 3000, 3001, 8080, 5432, 6379 are available
- **Database issues**: Ensure PostgreSQL is running and accessible
- **Service communication**: Verify all services are healthy

#### Production
- **ECS service not starting**: Check CloudWatch logs and task definition
- **ALB health check failing**: Verify service is running on correct port
- **SQS messages not processing**: Check service logs and IAM permissions

### Useful Commands

```bash
# Check service health
curl http://localhost:3000/api/v1/secret_santa/health

# View service logs
docker-compose logs api-gateway

# Check ECS service status (production)
aws ecs describe-services --cluster secret-santa-cluster --services secret-santa-api-gateway

# View CloudWatch logs (production)
aws logs tail /ecs/secret-santa-api-gateway --follow
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with modern microservices best practices
- Leverages AWS cloud-native services
- Implements comprehensive CI/CD and monitoring
- Designed for production scalability and reliability
