data "aws_availability_zones" "this" {}

data "aws_caller_identity" "this" {}

data "aws_ecs_task_definition" "this" {
  task_definition = aws_ecs_task_definition.this.family
}

data "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"
}

data "aws_region" "current" {}

data "aws_route53_zone" "this" {
  name = var.public_domain

  private_zone = false
}