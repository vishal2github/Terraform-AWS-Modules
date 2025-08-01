provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "students_record_table" {
  name           = var.table_name
  hash_key       = var.hash_key
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  billing_mode   = "PROVISIONED"

  attribute {
    name = var.hash_key
    type = "S"
  }
}
