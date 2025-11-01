terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.region
}

# 1) GitHub OIDC provider

data "aws_iam_openid_connect_provider" "github" {
  arn = var.github_oidc_provider_arn != "" ? var.github_oidc_provider_arn : null
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.github_oidc_provider_arn == "" ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

locals {
  oidc_arn = var.github_oidc_provider_arn != "" ? var.github_oidc_provider_arn : aws_iam_openid_connect_provider.github[0].arn
}

# 2) Role for GitHub Actions (assume via OIDC)

resource "aws_iam_role" "github_actions_role" {
  name               = "${var.name}-gha-oidc-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" : [
            "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/*",
            "repo:${var.github_owner}/${var.github_repo}:pull_request"
          ]
        },
        StringEquals = {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }]
  })
}

# Permissions for CI/CD (ECR push, EKS deploy)

data "aws_iam_policy_document" "gha_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:DescribeRepositories",
      "ecr:CreateRepository",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "eks:DescribeCluster"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "sts:AssumeRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gha_policy" {
  name   = "${var.name}-gha-oidc-policy"
  policy = data.aws_iam_policy_document.gha_policy.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.gha_policy.arn
}

# 3) ECR repositories
resource "aws_ecr_repository" "users" {
  name = "${var.name}-users"
  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_repository" "orders" {
  name = "${var.name}-orders"
  image_scanning_configuration { scan_on_push = true }
}

output "gha_role_arn" { 
    value = aws_iam_role.github_actions_role.arn 
    }

output "ecr_users_url" { 
    value = aws_ecr_repository.users.repository_url 
    }

output "ecr_orders_url" { 
    value = aws_ecr_repository.orders.repository_url 
    }
