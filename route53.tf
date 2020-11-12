data "aws_route53_zone" "witkozis" {
  name         = "witkozis.com."
  private_zone = false
}

resource "aws_route53_record" "webservers" {
  zone_id  = data.aws_route53_zone.witkozis.zone_id
  name     = join(".", ["fargate", data.aws_route53_zone.witkozis.name])
  type     = "A"
  alias {
    name                   = aws_alb.main.dns_name
    zone_id                = aws_alb.main.zone_id
    evaluate_target_health = true
  }
}