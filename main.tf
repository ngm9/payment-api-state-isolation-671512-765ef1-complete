locals {
  service_name = "payment-api"

  # Per-environment desired counts for the payment API service.
  staging_desired_count = 2
  prod_desired_count    = 3
}

# ---------------------------------------------------------------------------
# Remote state backend infrastructure (S3 bucket + intended lock table)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "tf_state" {
  bucket = "payments-tf-state"
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "payments-tf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ---------------------------------------------------------------------------
# IAM execution role shared by the payment API services
# ---------------------------------------------------------------------------
resource "aws_iam_role" "payment_api_exec" {
  name = "${local.service_name}-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# ECS-style infrastructure for the payment API
# ---------------------------------------------------------------------------
resource "aws_ecs_cluster" "payments" {
  name = "${local.service_name}-cluster"
}

resource "aws_ecs_task_definition" "payment_api" {
  family                   = local.service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.payment_api_exec.arn

  container_definitions = jsonencode([
    {
      name      = local.service_name
      image     = "payments/api:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# Both staging and production services are defined in the same root module
# and tracked in the same state.
resource "aws_ecs_service" "payment_api_staging" {
  name            = "${local.service_name}-staging"
  cluster         = aws_ecs_cluster.payments.id
  task_definition = aws_ecs_task_definition.payment_api.arn
  desired_count   = local.staging_desired_count
  launch_type     = "FARGATE"

  tags = {
    environment = "staging"
  }
}

resource "aws_ecs_service" "payment_api_prod" {
  name            = "${local.service_name}-prod"
  cluster         = aws_ecs_cluster.payments.id
  task_definition = aws_ecs_task_definition.payment_api.arn
  desired_count   = local.prod_desired_count
  launch_type     = "FARGATE"

  tags = {
    environment = "prod"
  }
}
