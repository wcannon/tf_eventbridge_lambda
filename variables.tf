variable "rate_in_minutes" {
  description = "Value of Cloudwatch Eventbridge schedule in minutes"
  type        = number
  default     = 720 # every 12 hours
}

