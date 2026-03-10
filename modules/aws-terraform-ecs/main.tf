resource "aws_ecs_cluster" "this" {
  name = "${var.labels.id}-cluster"
  tags = var.labels.tags
}

resource "aws_iam_role" "task_execution" {
  name = "${var.labels.id}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = var.labels.tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name = "${var.labels.id}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = var.labels.tags
}

resource "aws_iam_role_policy" "task_role" {
  name   = "${var.labels.id}-ecs-task-policy"
  role   = aws_iam_role.task_role.id
  policy = var.task_iam_policy_json
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.labels.id}"
  retention_in_days = 7
  tags              = var.labels.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.labels.id}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name        = var.container_name
      image       = var.container_image
      essential   = true
      command     = var.container_command
      environment = var.container_environment

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.container_name
        }
      }
    }
  ])

  tags = var.labels.tags
}
