data "aws_acm_certificate" "witkozis" {
    domain   = "*.witkozis.com"
    statuses = ["ISSUED"]
}