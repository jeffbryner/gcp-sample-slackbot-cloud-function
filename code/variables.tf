variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = ""
}

variable "function_name" {
  description = "The name of the function"
  type        = string
  default     = "function"
}

variable "default_region" {
  description = "Default region to create resources where applicable."
  type        = string
  default     = "us-central1"
}
