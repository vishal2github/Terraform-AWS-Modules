provider "aws" {
  region = var.region
}

resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "bucket" {
  bucket        = "whizbucket-${random_string.random.result}"
  force_destroy = true
}

resource "aws_sns_topic" "topic" {
  name   = "whiz-s3-event-notification"
  policy = <<POLICY
{
    "Version":"2012-10-17",
    "Statement":[
        {
        "Effect": "Allow",
        "Principal": { "Service": "s3.amazonaws.com" },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:*:*:whiz-s3-event-notification",
        "Condition":{
            "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.bucket.arn}"}
            }
        }
    ]
}
POLICY
  tags = {
    Name = "whiz-s3-event-notification"
  }
}

resource "aws_sns_topic_subscription" "topic-subscription" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.endpoint_client
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id
  topic {
    topic_arn = aws_sns_topic.topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

output "s3-bucket-name" {
  value = aws_s3_bucket.bucket.id
}

output "sns-topic-arn" {
  value = aws_sns_topic.topic.arn
}
