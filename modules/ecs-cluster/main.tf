# ECS Cluster Module

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "bia-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# User data script for ECS instances
locals {
  user_data = base64encode(<<-EOF
    #!/bin/sh
    echo ECS_CLUSTER=bia-${var.environment}-cluster >> /etc/ecs/ecs.config
    sudo dd if=/dev/zero of=/swapfile bs=128M count=32
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    yum update -y
    yum install -y ecs-init
    service docker start
    start ecs
  EOF
  )
}

# Launch Template for ECS Instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "bia-${var.environment}-launch-template-"
  image_id      = "ami-01cbd8cecccfed7dd" # ECS-optimized AMI
  instance_type = var.env_config.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    arn = var.instance_profile_arn
  }

  user_data = local.user_data

  network_interfaces {
    associate_public_ip_address = var.env_config.use_private_subnets ? false : true
    delete_on_termination       = true
    device_index                = 0
    security_groups             = [var.security_group_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "bia-${var.environment}-ecs"
    })
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Auto Scaling Group for EC2 Instances
resource "aws_autoscaling_group" "ecs" {
  name                  = "bia-${var.environment}-asg"
  vpc_zone_identifier   = var.subnet_ids
  min_size              = var.env_config.instance_min_capacity
  max_size              = var.env_config.instance_max_capacity
  desired_capacity      = var.env_config.instance_desired_capacity
  health_check_type     = "EC2"
  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "bia-${var.environment}-ecs"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "main" {
  name = "bia-${var.environment}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 10000
      instance_warmup_period    = 300
    }
  }

  depends_on = [aws_autoscaling_group.ecs]

  tags = var.tags

  lifecycle {
    prevent_destroy       = false
    create_before_destroy = false
  }
}

# Associate Capacity Provider with Cluster
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 1
    capacity_provider = aws_ecs_capacity_provider.main.name
  }

  depends_on = [aws_ecs_capacity_provider.main, aws_ecs_cluster.main]

  lifecycle {
    prevent_destroy       = false
    create_before_destroy = false
  }
}

# EC2 Instances Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "bia-${var.environment}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "bia-${var.environment}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  policy_type            = "SimpleScaling"
}

# CloudWatch Alarms for EC2 Instance Scaling
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "bia-${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "bia-${var.environment}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs.name
  }
}
