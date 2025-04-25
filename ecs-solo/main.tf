locals {
  image_name          = "nginxdemo"
  image_tag           = "latest"
  ecs_task_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ssl_policy_name     = "ELBSecurityPolicy-2016-08"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "current" {
  state = "available"
}

data "aws_acm_certificate" "certificate" {
  domain   = var.domain_name
  statuses = ["ISSUED"]

  most_recent = true
}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

module "vpc" {
  source = "../modules/vpc"

  identifier = "${local.image_name}-vpc"

  availability_zones = data.aws_availability_zones.current.names

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_flow_logs   = false
  enable_nat_gateway = false


  default_tags = merge(var.default_tags, {
    Name = "${local.image_name}-vpc"
  })
}




resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${local.image_name}"
  retention_in_days = 7
}

resource "aws_security_group" "ecs" {
  name        = "ecs-sg"
  description = "Allow HTTP"
  vpc_id      = module.vpc.vpc_id

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

  tags = merge(var.default_tags, {
    Name = "${local.image_name}-ecs-sg"
  })
}

resource "aws_security_group" "alb" {
  name        = "${local.image_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default_tags, {
    Name = "${local.image_name}-alb-sg"
  })
}


resource "aws_ecs_cluster" "cluster" {
  name = "${local.image_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = merge(var.default_tags, {
    Name = "${local.image_name}-ecs-cluster"
  })
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${local.image_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn


  memory = 512
  cpu    = 256

  container_definitions = jsonencode([
    {
      name      = "${local.image_name}"
      image     = "nginxdemos/hello:latest",
      essential = true,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/${local.image_name}",
          awslogs-region        = data.aws_region.current.name,
          awslogs-create-group  = "true",
          awslogs-stream-prefix = "ecs"
        }
      }
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
    }
  ])
}

resource "aws_ecs_service" "service" {
  name            = "${local.image_name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn


  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = local.image_name
    container_port   = 80
  }

  depends_on = [aws_cloudwatch_log_group.ecs_log_group]
}


resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.image_name}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = local.ecs_task_policy_arn
}


resource "aws_lb" "primary" {
  name            = "${local.image_name}-alb"
  security_groups = [aws_security_group.alb.id]
  subnets         = module.vpc.public_subnet_ids

  enable_deletion_protection       = false
  enable_http2                     = true
  enable_cross_zone_load_balancing = false
  enable_waf_fail_open             = false

  load_balancer_type = "application"

  internal = false

  tags = merge(var.default_tags, {
    Name = "${local.image_name}-alb"
  })
}


resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.primary.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.primary.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = local.ssl_policy_name
  certificate_arn   = data.aws_acm_certificate.certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${local.image_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-399"
  }

  tags = merge(var.default_tags, {
    Name = "${local.image_name}-tg"
  })
}


resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }
}
