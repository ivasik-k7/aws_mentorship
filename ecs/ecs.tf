resource "aws_security_group" "ecs_tasks" {
  name        = "${local.app_name}-ecs-tasks-sg"
  description = "Allow traffic to ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default_tags, {
    Name = "${local.app_name}-ecs-tasks-sg"
  })
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

resource "aws_ecs_task_definition" "main" {
  family                   = "${local.app_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "nginx-container"
    image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.image_name}:${local.image_tag}"


    essential = true,
    portMappings = [{
      containerPort = 80,
      hostPort      = 80,
      protocol      = "tcp"
    }],
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-region"        = data.aws_region.current.name,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "app" {
  name = "${local.app_name}-service"

  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.main.arn

  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnet_ids
    security_groups  = [aws_security_group.alb.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "nginx-container"
    container_port   = 80
  }

  tags = merge(var.default_tags, {
    Name = "${local.app_name}-ecs-service"
  })
}
