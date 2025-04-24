locals {
  image_name          = "static-demo"
  image_tag           = "latest"
  app_name            = "${var.environment}-static-demo-service"
  ecs_task_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ssl_policy_name     = "ELBSecurityPolicy-2016-08"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "current" {
  state = "available"
}


resource "aws_ecr_repository" "static_demo" {
  name                 = local.image_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.default_tags, {
    Name = "${local.app_name}-ecr-repo"
  })
}


resource "null_resource" "build_and_push_static_demo" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com

      docker build -t ${local.image_name}:${local.image_tag} ./docker
      docker tag ${local.image_name}:${local.image_tag} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.image_name}:${local.image_tag}
      docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.image_name}:${local.image_tag}
    EOT
  }

  depends_on = [aws_ecr_repository.static_demo]
}

resource "aws_ecs_cluster" "cluster" {
  name = "${local.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = merge(var.default_tags, {
    Name = "${local.app_name}-ecs-cluster"
  })
}

resource "aws_ecs_task_definition" "task" {
  family                   = "my-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "my-app-container"
    image     = "${aws_ecr_repository.static_demo.repository_url}:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

resource "aws_ecs_service" "service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_default_subnet.default_subnet.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = local.ecs_task_policy_arn
}


resource "aws_default_vpc" "default_vpc" {
}

resource "aws_default_subnet" "default_subnet" {
  availability_zone = data.aws_availability_zones.current.names[0]
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-security-group"
  description = "Allow inbound traffic"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
