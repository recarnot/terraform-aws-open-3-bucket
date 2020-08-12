resource "aws_s3_bucket" "logs" {
  count = var.logs ? 1 : 0

  bucket_prefix = format(var.label_formatter, "${var.prefix}-logs")
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  dynamic "server_side_encryption_configuration" {
    for_each = local.encryption_settings
    iterator = option

    content {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = option.value.kms_master_key_id
          sse_algorithm     = option.value.sse_algorithm
        }
      }
    }
  }

  tags = merge(
    {
      "Name" = format(var.label_formatter, "${var.prefix}-logs")
    },
    var.tags
  )
}

resource "aws_kms_key" "main" {
  count = var.encryption ? 1 : 0

  description         = format(var.label_formatter, "${var.prefix}-key")
  enable_key_rotation = true

  tags = merge(
    {
      "Name" = format(var.label_formatter, "${var.prefix}-key")
    },
    var.tags
  )
}

resource "aws_s3_bucket" "main" {
  bucket_prefix = format(var.label_formatter, var.prefix)
  acl           = var.acl
  force_destroy = true

  versioning {
    enabled = var.versioning
  }

  dynamic "logging" {
    for_each = local.logs_settings
    content {
      target_bucket = aws_s3_bucket.logs[0].id
      target_prefix = "logs/"
    }
  }

  dynamic "server_side_encryption_configuration" {
    for_each = local.encryption_settings
    iterator = option

    content {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = option.value.kms_master_key_id
          sse_algorithm     = option.value.sse_algorithm
        }
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = local.lifecycle_rule

    content {
      id      = lookup(lifecycle_rule.value, "id", null)
      enabled = lifecycle_rule.value.enabled

      dynamic "transition" {
        for_each = lookup(lifecycle_rule.value, "transition", [])

        content {
          days          = lookup(transition.value, "days", null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = length(keys(lookup(lifecycle_rule.value, "expiration", {}))) == 0 ? [] : [lookup(lifecycle_rule.value, "expiration", {})]

        content {
          days = lookup(expiration.value, "days", null)
        }
      }
    }
  }

  tags = merge(
    {
      "Name" = format(var.label_formatter, var.prefix)
    },
    var.tags
  )
}