output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "ecs_service_id" {
  description = "The ECS service ID"
  value       = aws_ecs_service.this.id
}

output "ecs_task_role_arn" {
  description = "IAM Role ARN for ECS tasks"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_execution_role_arn" {
  description = "IAM Role ARN for ECS task execution"
  value       = aws_iam_role.ecs_execution_role.arn
}
