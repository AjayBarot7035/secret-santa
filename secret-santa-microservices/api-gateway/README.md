# Secret Santa API Gateway

This is the API Gateway for the Secret Santa microservice architecture. It provides a unified interface for the entire system.

## Architecture

The API Gateway acts as the entry point for all client requests and routes them to the appropriate microservices:

- **CSV Parser Service (Go)**: Handles CSV data parsing
- **Assignment Service (Rails)**: Handles Secret Santa assignment logic

## API Endpoints

### Health Check
```
GET /api/v1/secret_santa/health
```

Returns the health status of the API Gateway.

### Generate Assignments
```
POST /api/v1/secret_santa/generate_assignments
```

Generates Secret Santa assignments from CSV data.

**Request Body:**
```json
{
  "csv_data": "name,email\nJohn Doe,john@example.com\nJane Smith,jane@example.com",
  "previous_assignments": []
}
```

**Response:**
```json
{
  "success": true,
  "assignments": [
    {
      "employee_name": "John Doe",
      "employee_email": "john@example.com",
      "secret_child_name": "Jane Smith",
      "secret_child_email": "jane@example.com"
    }
  ]
}
```

## Environment Variables

- `CSV_PARSER_SERVICE_URL`: URL of the CSV Parser Service (default: http://localhost:8080)
- `ASSIGNMENT_SERVICE_URL`: URL of the Assignment Service (default: http://localhost:3001)

## Running the Service

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Create database:
   ```bash
   bundle exec rails db:create
   ```

3. Start the server:
   ```bash
   bundle exec rails server -p 3000
   ```

## Testing

Run the test suite:
```bash
bundle exec rspec
```

## Service Communication

The API Gateway communicates with other services using HTTP requests:

1. **CSV Parser Service**: Sends CSV data for parsing
2. **Assignment Service**: Sends parsed employee data for assignment generation

All communication is done via JSON over HTTP with proper error handling and retry logic.
