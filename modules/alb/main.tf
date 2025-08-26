resource "aws_lb" "bia_alb" {
  name               = "bia-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-alb"
  })
}

resource "aws_lb_target_group" "bia_tg" {
  name     = "bia-${var.environment}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,302"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-tg"
  })
}

resource "aws_lb_listener" "bia_listener" {
  load_balancer_arn = aws_lb.bia_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bia_tg.arn
  }
}
