resource "aws_cognito_user_pool" "this" {
  name = "${var.labels.id}-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = var.labels.tags
}

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.labels.id}-client"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 7

  prevent_user_existence_errors = "ENABLED"
}

# Test user — SUPPRESS skips the welcome email so CI stays quiet.
# The user starts in FORCE_CHANGE_PASSWORD state; the test script handles
# the NEW_PASSWORD_REQUIRED challenge on first auth.
resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.this.id
  username     = var.user_email

  attributes = {
    email          = var.user_email
    email_verified = "true"
  }

  temporary_password = var.user_temp_password
  message_action     = "SUPPRESS"
}
