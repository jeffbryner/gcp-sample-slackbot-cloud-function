variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = ""
}

variable "function_name" {
  description = "The name of the function"
  type        = string
  default     = "slackbot"
}

variable "default_region" {
  description = "Default region to create resources where applicable."
  type        = string
  default     = "us-central1"
}

variable "slack_bot_token" {
  description = "The slackbot token (starts with xoxb-)"
  type        = string
  sensitive   = true
}

variable "slack_signing_secret" {
  description = "The signing secret for your bot (app credentials page of your bot)"
  type        = string
  sensitive   = true
}
