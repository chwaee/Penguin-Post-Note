provider "aws" {
  region = "us-east-1"
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"

  name = "penguin-post-note"

  capacity_providers = ["FARGATE"]

  tags = {
    Terraform = "true"
    Environment = "main"
  }
}

resource "aws_ecs_task_definition" "app" {
  family = "penguin-post-note"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "2"
  memory = "256"
  execution_role_arn = module.ecs.execution_role_arn
  task_role_arn = module.ecs.task_role_arn

  container_definitions = jsonencode([
    {
      name = "penguin-post-note"
      image = "chwaee/penguin-post-note:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort = 3000
        }
      ]
      environment = [
        { name = "DATABASE_URL", value = var.DATABASE_URL }
      ]
    }
  ])
}

resource "aws_security_group" "lb" {
  name        = "load_balancer"
  description = "Allow inbound traffic"
}

resource "aws_security_group_rule" "allow_all" {
  security_group_id = aws_security_group.lb.id

  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "app" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]

  tags = {
    Terraform   = "true"
    Environment = "main"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group" "app" {
  name     = "app-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.ecs.vpc_id

    
health_check {
  enabled = true
  healthy_threshold = 3
  interval = 30
  matcher = "200-399"
  path = "/"
  port = "traffic-port"
  protocol = "HTTP"
  timeout = 5
  unhealthy_threshold = 3
}

tags = {
  Terraform = "true"
  Environment = "main"
}

}

resource "aws_ecs_service" "app" {
    name = "app-service"
    cluster = module.ecs.cluster_id
    task_definition = aws_ecs_task_definition.app.arn
    desired_count = 1
    launch_type = "FARGATE"

    network_configuration {
        subnets = module.ecs.private_subnets
        security_groups = [aws_security_group.lb.id]
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.app.arn
        container_name = "app"
        container_port = 3000
    }

    depends_on = [aws_lb_listener.front_end]
}