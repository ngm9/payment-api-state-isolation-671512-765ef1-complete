variable "aws_region" {
  description = "AWS region for the payment API infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "service_image" {
  description = "Container image reference for the payment API service."
  type        = string
  default     = "payments/api:latest"
}

variable "environment" {
  description = "Logical environment label used for tagging the payment API resources."
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "environment must be one of: staging, prod."
  }
}
