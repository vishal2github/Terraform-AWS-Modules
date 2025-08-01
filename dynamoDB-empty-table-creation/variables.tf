variable "table_name" {
  description = "The name of the DynamoDB table."
  type        = string
  default     = "tf-table" # Optional fallback
}

variable "hash_key" {
  description = "The hash key for the DynamoDB table."
  type        = string
  default     = "id" # Optional fallback
}

variable "read_capacity" {
  description = "The read capacity units for the DynamoDB table."
  type        = number
  default     = 5 # Optional fallback
}

variable "write_capacity" {
  description = "The write capacity units for the DynamoDB table."
  type        = number
  default     = 5 # Optional fallback
}
