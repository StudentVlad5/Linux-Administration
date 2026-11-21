variable "bucket_name" {
  description = "Ім'я S3-бакета для зберігання Terraform state"
  type        = string
}

variable "table_name" {
  description = "Ім'я таблиці DynamoDB для блокування стейтів"
  type        = string
  default     = "terraform-locks"
}