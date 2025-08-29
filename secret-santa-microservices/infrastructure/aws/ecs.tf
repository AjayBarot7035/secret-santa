# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition for CSV Parser
resource "aws_ecs_task_definition" "csv_parser" {
  family                   = "${var.project_name}-csv-parser"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.secret_santa_service_role.arn

  container_definitions = jsonencode([
    {
      name  = "csv-parser"
      image = "${aws_ecr_repository.csv_parser.repository_url}:latest"

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "SQS_QUEUE_CSV_PARSER"
          value = aws_sqs_queue.csv_parser.name
        },
        {
          name  = "SNS_TOPIC_EMPLOYEE_DATA_PARSED"
          value = aws_sns_topic.employee_data_parsed.name
        }
      ]

      secrets = [
        {
          name      = "AWS_ACCESS_KEY_ID"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/aws-credentials:access_key_id::"
        },
        {
          name      = "AWS_SECRET_ACCESS_KEY"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/aws-credentials:secret_access_key::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-csv-parser"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-csv-parser-task"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ECS Task Definition for Assignment Service
resource "aws_ecs_task_definition" "assignment_service" {
  family                   = "${var.project_name}-assignment-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.secret_santa_service_role.arn

  container_definitions = jsonencode([
    {
      name  = "assignment-service"
      image = "${aws_ecr_repository.assignment_service.repository_url}:latest"

      portMappings = [
        {
          containerPort = 3001
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "RAILS_ENV"
          value = "production"
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "SQS_QUEUE_ASSIGNMENT_SERVICE"
          value = aws_sqs_queue.assignment_service.name
        },
        {
          name  = "SNS_TOPIC_ASSIGNMENTS_GENERATED"
          value = aws_sns_topic.assignments_generated.name
        },
        {
          name  = "ENABLE_SQS_PROCESSOR"
          value = "true"
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/database:url::"
        },
        {
          name      = "REDIS_URL"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/redis:url::"
        },
        {
          name      = "AWS_ACCESS_KEY_ID"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/aws-credentials:access_key_id::"
        },
        {
          name      = "AWS_SECRET_ACCESS_KEY"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/aws-credentials:secret_access_key::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-assignment-service"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3001/api/v1/assignments/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-assignment-service-task"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ECS Task Definition for API Gateway
resource "aws_ecs_task_definition" "api_gateway" {
  family                   = "${var.project_name}-api-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.secret_santa_service_role.arn

  container_definitions = jsonencode([
    {
      name  = "api-gateway"
      image = "${aws_ecr_repository.api_gateway.repository_url}:latest"

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "RAILS_ENV"
          value = "production"
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "SNS_TOPIC_EMPLOYEE_DATA_RAW"
          value = aws_sns_topic.employee_data_raw.name
        },
        {
          name  = "SQS_QUEUE_ASSIGNMENTS_COMPLETED"
          value = aws_sqs_queue.assignments_completed.name
        },
        {
          name  = "CSV_PARSER_SERVICE_URL"
          value = "http://${aws_service_discovery_service.csv_parser.name}.${aws_service_discovery_private_dns_namespace.main.name}:8080"
        },
        {
          name  = "ASSIGNMENT_SERVICE_URL"
          value = "http://${aws_service_discovery_service.assignment_service.name}.${aws_service_discovery_private_dns_namespace.main.name}:3001"
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/database:url::"
        },
        {
          name      = "REDIS_URL"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/redis:url::"
        },
        {
          name      = "AWS_ACCESS_KEY_ID"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/aws-credentials:access_key_id::"
        },
        {
          name      = "AWS_SECRET_ACCESS_KEY"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/aws-credentials:secret_access_key::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-api-gateway"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000/api/v1/secret_santa/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-api-gateway-task"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}.local"
  description = "Service discovery namespace for ${var.project_name}"
  vpc         = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-service-discovery"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Service Discovery Services
resource "aws_service_discovery_service" "csv_parser" {
  name = "csv-parser"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name        = "${var.project_name}-csv-parser-discovery"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_service_discovery_service" "assignment_service" {
  name = "assignment-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name        = "${var.project_name}-assignment-service-discovery"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ECS Services
resource "aws_ecs_service" "csv_parser" {
  name            = "${var.project_name}-csv-parser"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.csv_parser.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.csv_parser.arn
  }

  tags = {
    Name        = "${var.project_name}-csv-parser-service"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_service" "assignment_service" {
  name            = "${var.project_name}-assignment-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.assignment_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.assignment_service.arn
  }

  tags = {
    Name        = "${var.project_name}-assignment-service"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_service" "api_gateway" {
  name            = "${var.project_name}-api-gateway"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api_gateway.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api_gateway.arn
    container_name   = "api-gateway"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name        = "${var.project_name}-api-gateway-service"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
