# outputs.tf

output "alb_hostname" {
  value = aws_alb.main.dns_name
}

output "aws_acc_arn" {
  value = data.aws_elb_service_account.main.arn
}