variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "endpoint_client" {
  description = "SNS topic subscription endpoint"
  type        = string
}
