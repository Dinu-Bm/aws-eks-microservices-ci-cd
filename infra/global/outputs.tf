output "gha_role_arn" { 
    value = aws_iam_role.github_actions_role.arn 
    }

output "ecr_users_url" { 
    value = aws_ecr_repository.users.repository_url 
    }

output "ecr_orders_url" { 
    value = aws_ecr_repository.orders.repository_url 
    }
