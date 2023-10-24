variable "location" {
  type        = string
  default     = "west us"
  description = "Azure location"
}

variable "short_location" {
  type        = string
  default     = "wus"
  description = "Please provide short location index in 2-4 letters"
}

variable "subscription_id" {
  type        = string
  description = "subscription_id"
}

variable "tenant_id" {
  type        = string
  description = "tenant_id"
}

variable "prefix" {
  type        = string
  default     = "test"
  description = "description"
}

