resource "aws_cognito_user_pool" "this" {
  name = "${var.environment}-cognito-user-pool"

  deletion_protection = "INACTIVE"

  password_policy {
    minimum_length                   = 8
    require_numbers                  = true
    require_uppercase                = true
    require_lowercase                = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  schema {
    attribute_data_type      = "String"
    name                     = "email"
    required                 = true
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  auto_verified_attributes = ["email"]

  mfa_configuration = "OFF"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  device_configuration {
    challenge_required_on_new_device      = false
    device_only_remembered_on_user_prompt = false
  }

  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_LINK"
    email_message        = "Your verification code is {####}"
    email_subject        = "Your verification code"
  }


  tags = merge(var.default_tags, {
    Name        = "${var.environment}-cognito-user-pool"
    Environment = var.environment
  })
}

resource "aws_cognito_identity_provider" "google" {
  count         = 0
  user_pool_id  = aws_cognito_identity_pool.this.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    client_id        = var.google_client_id
    client_secret    = var.google_client_secret
    authorize_scopes = "openid email profile"
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
  }
}

resource "aws_cognito_identity_provider" "apple" {
  count         = 0
  user_pool_id  = aws_cognito_identity_pool.this.id
  provider_name = "SignInWithApple"
  provider_type = "SignInWithApple"

  provider_details = {
    client_id        = var.apple_client_id
    team_id          = var.apple_team_id
    key_id           = var.apple_key_id
    private_key      = var.apple_private_key
    authorize_scopes = "email name"
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
  }

}

resource "aws_cognito_identity_provider" "facebook" {
  count         = 0
  user_pool_id  = aws_cognito_identity_pool.this.id
  provider_name = "Facebook"
  provider_type = "Facebook"

  provider_details = {
    client_id     = var.facebook_client_id
    client_secret = var.facebook_client_secret
  }

  attribute_mapping = {
    email    = "email"
    username = "id"
  }

}

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.environment}-cognito-user-pool-client"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret               = false
  refresh_token_validity        = 30
  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  callback_urls = ["https://oauth.pstmn.io/v1/callback"]
  logout_urls   = ["https://example.com"]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  supported_identity_providers = [
    "COGNITO",
    # "Google", # Uncomment when Google provider is enabled
    # "Facebook", # Uncomment when Facebook provider is enabled
    # "SignInWithApple", # Uncomment when Apple provider is enabled
  ]
}

resource "aws_cognito_identity_pool" "this" {
  identity_pool_name               = "${var.environment}-cognito-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.this.id
    provider_name           = aws_cognito_user_pool.this.endpoint
    server_side_token_check = true
  }
}

resource "aws_iam_role" "authenticated_role" {
  name = "cognito_authenticated_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.this.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "authenticated_policy" {
  name = "cognito_authenticated_policy"
  role = aws_iam_role.authenticated_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "mobileanalytics:PutEvents",
          "cognito-sync:*",
          "cognito-identity:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.this.id

  roles = {
    "authenticated" = aws_iam_role.authenticated_role.arn
  }
}

