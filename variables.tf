variable "label_formatter" {
  description = "Formatter use to format name or others labels"
  type        = string
  default     = "%s"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "prefix" {
  description = "Bucket prefix"
  type        = string
}

variable "acl" {
  description = "Bucket Access Control List option"
  type        = string
  default     = "private"
}

variable "versioning" {
  description = "Enable versioning. Default true"
  type        = bool
  default     = true
}

variable "logs" {
  description = "Enabled logs for this bucket"
  type        = bool
  default     = false
}

variable "encryption" {
  description = "Enable default encryption"
  type        = bool
  default     = false
}


variable "transition_30_days" {
  description = "Transition to 'Standard IA' after 30 days"
  type        = bool
  default     = false
}

variable "transition_60_days" {
  description = "Transition to 'Glacier' after 60 days"
  type        = bool
  default     = false
}

variable "transition_90_days" {
  description = "Expiration after 90 days"
  type        = bool
  default     = false
}

locals {
  logs_settings = var.logs ? { enabled = true } : {}

  encryption_settings = var.encryption ? [{
    kms_master_key_id = aws_kms_key.main[0].id
    sse_algorithm     = "AES256"
  }] : []

  transition_30       = { days : "30", storage_class : "STANDARD_IA" }
  transition_60       = { days : "60", storage_class : "GLACIER" }
  transition_settings = concat([], var.transition_30_days ? [local.transition_30] : [], var.transition_60_days ? [local.transition_60] : [])
  expiration_settings = merge({}, var.transition_90_days ? { days : "90" } : {})
  lifecycle_enabled = length(local.transition_settings) > 0 || lookup(local.expiration_settings, "days", null) == "90"

  lifecycle_rule = local.lifecycle_enabled ? [{
    id : "id",
    enabled : local.lifecycle_enabled,
    transition : local.transition_settings,
    expiration : local.expiration_settings
  }] : []
}