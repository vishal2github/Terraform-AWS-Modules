output "table_name" {
  value = aws_dynamodb_table.students_record_table.name
}

output "table_arn" {
  value = aws_dynamodb_table.students_record_table.arn
}
