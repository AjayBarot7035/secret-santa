# 🎅 Secret Santa Generator

A magical Secret Santa assignment generator with an animated Christmas-themed UI, built with modern microservices architecture using Go and Ruby on Rails for local development and testing.

![Secret Santa Generator](screenshots/main-dashboard.png)
*The magical Secret Santa Generator dashboard with Santa's journey animation*

## ✨ Features

### 🎨 **Magical Christmas UI**
- **Santa's Journey Animation**: Watch Santa and his 8 reindeer fly across a starry night sky
- **Interactive Experience**: Give your participant list to Santa or his reindeer
- **Christmas Theme**: Beautiful red and green gradient with snow effects
- **Responsive Design**: Works perfectly on desktop, tablet, and mobile

### 📊 **CSV Upload & Management**
- **Drag & Drop**: Easy CSV file upload with visual feedback
- **Manual Entry**: Add participants one by one with validation
- **Previous Assignments**: Upload previous year's assignments to avoid repetitive pairings
- **Duplicate Detection**: Automatically removes duplicate names and emails
- **Real-time Preview**: See your participants as you add them

### 🎯 **Smart Assignment Generation**
- **Circular Assignment**: Each person gives to the next person in the circle
- **Constraint Handling**: Avoids previous year's assignments
- **Validation**: Ensures no one gets themselves or forbidden assignments
- **Progress Animation**: Watch Santa work his magic with real-time status updates

### 📤 **Export & Share**
- **CSV Export**: Download assignments in the exact format required
- **Share Results**: Copy assignments to clipboard or share via native sharing
- **Print Friendly**: Clean, printable assignment cards

### 📋 **CSV Format Support**

#### **Input Format (Participants)**
```csv
Name,Email
John Doe,john@example.com
Jane Smith,jane@example.com
Bob Johnson,bob@example.com
```

#### **Input Format (Previous Assignments)**
```csv
Employee_Name,Employee_EmailID,Secret_Child_Name,Secret_Child_EmailID
John Doe,john@example.com,Jane Smith,jane@example.com
Jane Smith,jane@example.com,Bob Johnson,bob@example.com
```

#### **Output Format (Generated Assignments)**
```csv
Employee_Name,Employee_EmailID,Secret_Child_Name,Secret_Child_EmailID
John Doe,john@example.com,Jane Smith,jane@example.com
Jane Smith,jane@example.com,Bob Johnson,bob@example.com
Bob Johnson,bob@example.com,John Doe,john@example.com
```

![CSV Upload Interface](screenshots/csv-upload.png)
*Easy CSV upload with drag & drop functionality*

![Participant Management](screenshots/participant-management.png)
*Clean participant list with easy removal options*

![Previous Assignments Upload](screenshots/previous-assignments.png)
*Upload previous year's assignments to avoid repetitive pairings*

![Assignment Generation Process](screenshots/assignment-process.png)
*Watch Santa work his magic with real-time progress updates*

![Assignment Results](screenshots/assignment-results.png)
*Beautiful assignment cards with export and share options*

![CSV Export Format](screenshots/csv-export.png)
*Perfect CSV export with correct field names and formatting*

## 🏗️ Architecture Overview

This project implements a modern microservices architecture with the following components:

- **CSV Parser Service (Go)**: Handles CSV data parsing and validation
- **Assignment Service (Rails)**: Generates Secret Santa assignments with business logic
- **API Gateway (Rails)**: Orchestrates requests and provides unified API
- **UI Service (HTML/CSS/JS)**: Modern, animated web interface for user interaction
- **Local Development**: Docker Compose for dependencies, HTTP communication between services

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Go 1.21+
- Ruby 3.3+

### Local Development

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd secret-santa
   ```

2. **Start local development environment**
   ```bash
   cd secret-santa-microservices
   ./start_local_dev.sh
   ```

3. **Access the UI**
   - Open your browser and go to: **http://localhost:8080**
   - Experience the magical Christmas-themed interface with Santa's journey animation
   - Upload CSV files or add participants manually
   - Watch Santa and his reindeer team work their magic!

![Santa's Journey Animation](screenshots/santa-animation.png)
*Santa and his 8 reindeer team flying across the night sky with stars and snowflakes*

4. **Test the API (Optional)**
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

5. **Stop local development**
   ```bash
   ./stop_local_dev.sh
   ```

## 📁 Project Structure

```
secret-santa-microservices/
├── csv-parser-service/         # Go CSV parsing service
│   ├── internal/csvparser/     # Core parsing logic
│   ├── main.go                 # HTTP server
│   └── go.mod                  # Go dependencies
├── assignment-service/         # Rails assignment generation service
│   ├── app/services/           # Business logic
│   ├── app/controllers/        # API endpoints
│   ├── spec/                   # RSpec tests
│   └── Gemfile                 # Ruby dependencies
├── api-gateway/                # Rails API gateway
│   ├── app/controllers/        # API orchestration
│   ├── spec/                   # RSpec tests
│   └── Gemfile                 # Ruby dependencies
├── ui-service/                 # Frontend web interface
│   ├── index.html              # Main HTML file
│   ├── styles.css              # CSS styles and animations
│   ├── script.js               # JavaScript functionality
├── docker-compose.local.yml    # Local development
├── start_local_dev.sh          # Local development script
├── stop_local_dev.sh           # Local development cleanup
└── README.md                   # Detailed project documentation
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

## 🔧 Configuration

### Environment Variables

#### CSV Parser Service
```bash
PORT=8081  # Default port for CSV Parser Service
```

#### Assignment Service
```bash
RAILS_ENV=development
DATABASE_URL=postgresql://postgres:password@localhost:5432/assignment_service_development
```

#### API Gateway
```bash
RAILS_ENV=development
DATABASE_URL=postgresql://postgres:password@localhost:5432/api_gateway_development
ASSIGNMENT_SERVICE_URL=http://localhost:3001
```

## 🛠️ Development Workflow

### Local Development

1. **Start services**: `./start_local_dev.sh`
2. **Make changes**: Edit code in your preferred IDE
3. **Run tests**: Execute test suites for affected services
4. **Test locally**: Use curl or Postman to test APIs
5. **Stop services**: `./stop_local_dev.sh`

## 🐛 Troubleshooting

### Common Issues

#### Local Development
- **Port conflicts**: Check if ports 3000, 3001, 8080, 5432, 6379 are available
- **Database issues**: Ensure PostgreSQL is running and accessible
- **Service communication**: Verify all services are healthy

### Useful Commands

```bash
# Check service health
curl http://localhost:3000/api/v1/secret_santa/health

# View service logs
docker-compose -f docker-compose.local.yml logs postgres
docker-compose -f docker-compose.local.yml logs redis
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
- Designed for local development and testing
- Implements clean architecture and separation of concerns
- Features a magical Christmas-themed user interface

## 📋 TODO

### Infrastructure & DevOps
- [ ] **AWS Setup** - Configure AWS infrastructure for production deployment
- [ ] **Terraform** - Implement Infrastructure as Code for AWS resources
- [ ] **AWS CLI Tasks** - Automate AWS operations and deployments
- [ ] **CI/CD Pipeline** - Set up continuous integration and deployment pipeline
- [ ] **Secret Management for AWS** - Implement secure secret storage using AWS Secrets Manager or Parameter Store

### Frontend Enhancement
- [ ] **Vue.js or React.js Application** - Replace plain JavaScript with modern frontend framework
- [ ] **UI Tweaks** - Improve user interface design and user experience

### Code Quality & Monitoring
- [ ] **Rubocop Fixes** - Address Ruby code style and quality issues
- [ ] **Observability Metrics** - Implement monitoring, logging, and metrics collection
