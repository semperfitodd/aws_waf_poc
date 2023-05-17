locals {
  image = "${data.aws_caller_identity.this.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/${var.environment}"

  port = 80
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.0.1"

  cluster_name = var.environment

  tags = var.tags
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 300
    target_value       = 65
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 20
  min_capacity       = 1
  resource_id        = "service/${module.ecs.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.environment}"
  retention_in_days = 3
  tags              = var.tags
}

resource "aws_ecs_service" "this" {
  name = var.environment

  cluster                            = module.ecs.cluster_id
  deployment_minimum_healthy_percent = 70
  desired_count                      = 1
  enable_ecs_managed_tags            = true
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  tags                               = var.tags

  task_definition = "${data.aws_ecs_task_definition.this.family}:${data.aws_ecs_task_definition.this.revision}"

  wait_for_steady_state = true

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    container_name   = var.environment
    container_port   = local.port
    target_group_arn = module.alb.target_group_arns[0]
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs.id]
    subnets          = module.vpc.private_subnets
  }

  depends_on = [module.alb]
}

resource "aws_ecs_task_definition" "this" {
  family = var.environment

  cpu                      = 512
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn
  memory                   = 1024
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      cpu       = 0
      essential = true
      image     = "${local.image}:latest"
      name      = var.environment

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.environment}"
          awslogs-region        = data.aws_region.current.id
          awslogs-stream-prefix = "ecs"
        }
      }

      portMappings = [
        {
          containerPort = local.port
          hostPort      = local.port
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = var.tags
}

resource "aws_security_group" "ecs" {
  name        = "${var.environment}_ecs"
  description = "${var.environment} ECS security group"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ecs_egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Managed by Terraform"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.ecs.id
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "ecs_ingress" {
  source_security_group_id = aws_security_group.alb.id
  description              = "Managed by Terraform"
  from_port                = local.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs.id
  to_port                  = local.port
  type                     = "ingress"
}