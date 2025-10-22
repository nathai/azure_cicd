# Repository Project Outputs
output "repo_project_id" {
  description = "ID of the Azure DevOps project that contains the repository"
  value       = data.azuredevops_project.repo_project.id
}

output "repo_project_name" {
  description = "Name of the Azure DevOps project that contains the repository"
  value       = data.azuredevops_project.repo_project.name
}

output "repo_project_url" {
  description = "URL of the Azure DevOps project that contains the repository"
  value       = "${var.org_service_url}/${data.azuredevops_project.repo_project.name}"
}

# Pipeline Project Outputs
output "pipeline_project_id" {
  description = "ID of the Azure DevOps project where pipelines are created"
  value       = data.azuredevops_project.pipeline_project.id
}

output "pipeline_project_name" {
  description = "Name of the Azure DevOps project where pipelines are created"
  value       = data.azuredevops_project.pipeline_project.name
}

output "pipeline_project_url" {
  description = "URL of the Azure DevOps project where pipelines are created"
  value       = "${var.org_service_url}/${data.azuredevops_project.pipeline_project.name}"
}

# Repository Outputs
output "repository_id" {
  description = "ID of the Git repository"
  value       = data.azuredevops_git_repository.repo.id
}

output "repository_name" {
  description = "Name of the Git repository"
  value       = data.azuredevops_git_repository.repo.name
}

output "repository_url" {
  description = "URL of the Git repository"
  value       = data.azuredevops_git_repository.repo.remote_url
}

# Build Pipeline Outputs
output "build_pipeline_id" {
  description = "ID of the build pipeline"
  value       = azuredevops_build_definition.build.id
}

output "build_pipeline_name" {
  description = "Name of the build pipeline"
  value       = azuredevops_build_definition.build.name
}

output "build_pipeline_url" {
  description = "URL of the build pipeline"
  value       = "${var.org_service_url}/${data.azuredevops_project.pipeline_project.name}/_build?definitionId=${azuredevops_build_definition.build.id}"
}

# Release Pipeline Outputs
output "release_pipeline_id" {
  description = "ID of the release pipeline"
  value       = azuredevops_build_definition.release.id
}

output "release_pipeline_name" {
  description = "Name of the release pipeline"
  value       = azuredevops_build_definition.release.name
}

output "release_pipeline_url" {
  description = "URL of the release pipeline"
  value       = "${var.org_service_url}/${data.azuredevops_project.pipeline_project.name}/_build?definitionId=${azuredevops_build_definition.release.id}"
}

# Environments Outputs
output "environments" {
  description = "Map of environment names to their IDs"
  value = var.create_environments ? {
    for env in azuredevops_environment.envs :
    env.name => env.id
  } : {}
}

# Variable Group Outputs
output "variable_group_id" {
  description = "ID of the variable group (if created)"
  value       = var.create_variable_group ? azuredevops_variable_group.pipeline_vars[0].id : null
}

output "variable_group_name" {
  description = "Name of the variable group (if created)"
  value       = var.create_variable_group ? azuredevops_variable_group.pipeline_vars[0].name : null
}
