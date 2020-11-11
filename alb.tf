# alb.tf

data "aws_elb_service_account" "main" {}

# resource "random_string" "randomer" {
#   length = 8
# }

# variable "bucket_name" {
#   default = "alb-access-logs-history-${random_string.randomer}"
# }

resource "aws_s3_bucket" "elb_logs" {
  bucket = "alb-access-logs-history"
  acl    = "private"
  force_destroy = true

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::alb-access-logs-history/AWSLogs/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
POLICY
}


resource "aws_alb" "main" {
  name            = "cb-load-balancer"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]

  access_logs {
    bucket  = aws_s3_bucket.elb_logs.bucket
    enabled = true
  }
}

resource "aws_alb_target_group" "app_http" {
  name        = "cb-target-group-http"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled = true
    # healthy_threshold   = "3"
    interval            = 10
    protocol            = "HTTP"
    matcher             = "200-399"
    # timeout             = "3"
    path                = var.health_check_path
    # unhealthy_threshold = "2"
  }
}

# resource "aws_alb_target_group" "app_https" {
#   name        = "cb-target-group-https"
#   port        = 443
#   protocol    = "HTTPS"
#   vpc_id      = aws_vpc.main.id
#   target_type = "ip"

  # health_check {
  #   healthy_threshold   = "3"
  #   interval            = "30"
  #   protocol            = "HTTPS"
  #   matcher             = "200"
  #   timeout             = "3"
  #   path                = var.health_check_path
  #   unhealthy_threshold = "2"
  # }
# }

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end_http" {
  load_balancer_arn = aws_alb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "front_end_https" {
  load_balancer_arn = aws_alb.main.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.witkozis.arn

  default_action {
    target_group_arn = aws_alb_target_group.app_http.id
    type             = "forward"
  }
}

