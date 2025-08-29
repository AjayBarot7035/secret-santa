terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# SNS Topics for message publishing
resource "aws_sns_topic" "employee_data_raw" {
  name = "secret-santa-employee-data-raw"
  tags = {
    Environment = var.environment
    Project     = "secret-santa"
  }
}

resource "aws_sns_topic" "employee_data_parsed" {
  name = "secret-santa-employee-data-parsed"
  tags = {
    Environment = var.environment
    Project     = "secret-santa"
  }
}

resource "aws_sns_topic" "assignments_requested" {
  name = "secret-santa-assignments-requested"
  tags = {
    Environment = var.environment
    Project     = "secret-santa"
  }
}

resource "aws_sns_topic" "assignments_generated" {
  name = "secret-santa-assignments-generated"
  tags = {
    Environment = var.environment
    Project     = "secret-santa"
  }
}

# SQS Queues for message processing
resource "aws_sqs_queue" "csv_parser_queue" {
  name = "secret-santa-csv-parser-queue"
  
  # Message retention and processing settings
  message_retention_seconds = 1209600  # 14 days
  visibility_timeout_seconds = 30
  receive_wait_time_seconds = 20  # Long polling
  
  # Dead letter queue for failed messages
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.csv_parser_queue.arn
    maxReceiveCount     = 3
  })
  
  tags = {
    Environment = var.environment
    Project     = "secret-santa"
  }
}

resource "aws_sqs_queue" "csv_parser_dlq" {
  name = "secret-santa-csv-parser-dlq"
  message_retention_seconds = 1209600  # 14 days
  
  tags = {
    Environment = var.environment
    Project     = "secret-santa"
  }
}

resource "aws_sqs_queue" "assignment_service_queue" {
  name = "secret-santa-assignment-service-queue"
  
  message_retention_seconds = 1209600  # 14 days
  visibility_timeout_seconds = 30
  receive_wait_time_seconds = 20  # Long polling
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.assignment_service_queue.arn
    maxReceiveCount     = 3
  })
  
  tags = {
    Environment = var.environment
    Project     = "secret-santa"
  }
}

resource "aws_sqs_queue" "assignment_service_dlq" {
  name = "secret-santa-assignment-service-dlq"
  message_retention_seconds = 1209600  # 14 days
  
  tags = {
    Environment = var.environment
    Project     = "secret-santa"
  }
}

# SNS Topic Subscriptions
resource "aws_sns_topic_subscription" "csv_parser_subscription" {
  topic_arn = aws_sns_topic.employee_data_raw.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.csv_parser_queue.arn
}

resource "aws_sns_topic_subscription" "assignment_service_subscription" {
  topic_arn = aws_sns_topic.employee_data_parsed.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.assignment_service_queue.arn
}

# SQS Queue Policies for SNS access
resource "aws_sqs_queue_policy" "csv_parser_queue_policy" {
  queue_url = aws_sqs_queue.csv_parser_queue.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.csv_parser_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.employee_data_raw.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "assignment_service_queue_policy" {
  queue_url = aws_sqs_queue.assignment_service_queue.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.assignment_service_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.employee_data_parsed.arn
          }
        }
      }
    ]
  })
}

# IAM Role for services to access SQS/SNS
resource "aws_iam_role" "service_role" {
  name = "secret-santa-service-role"
  
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
  
  tags = {
    Environment = var.environment
    Project     = "secret-santa"
  }
}

resource "aws_iam_policy" "sqs_sns_policy" {
  name = "secret-santa-sqs-sns-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          aws_sqs_queue.csv_parser_queue.arn,
          aws_sqs_queue.assignment_service_queue.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.employee_data_parsed.arn,
          aws_sns_topic.assignments_requested.arn,
          aws_sns_topic.assignments_generated.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "service_role_policy" {
  role       = aws_iam_role.service_role.name
  policy_arn = aws_iam_policy.sqs_sns_policy.arn
}

# Outputs
output "sns_topics" {
  description = "SNS Topic ARNs"
  value = {
    employee_data_raw     = aws_sns_topic.employee_data_raw.arn
    employee_data_parsed  = aws_sns_topic.employee_data_parsed.arn
    assignments_requested = aws_sns_topic.assignments_requested.arn
    assignments_generated = aws_sns_topic.assignments_generated.arn
  }
}

output "sns_topics" {
  description = "SQS Queue URLs"
  value = {
    csv_parser_queue        = aws_sqs_queue.csv_parser_queue.url
    csv_parser_dlq          = aws_sqs_queue.csv_parser_dlq.url
    assignment_service_queue = aws_sqs_queue.assignment_service_queue.url
    assignment_service_dlq   = aws_sqs_queue.assignment_service_dlq.url
  }
}

output "service_role_arn" {
  description = "IAM Role ARN for services"
  value       = aws_iam_role.service_role.arn
}
