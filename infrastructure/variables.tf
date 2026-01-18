variable "prod_bucket_name" {
  description = "Production bucket name"
  type        = string
  default     = "app-production-data-v1"
}

variable "backup_bucket_name" {
  description = "Backup bucket name"
  type        = string
  default     = "app-backup-storage-v1"
}

variable "aws_region" {
  description = "region AWS (LocalStack)"
  type        = string
  default     = "sa-east-1"
}