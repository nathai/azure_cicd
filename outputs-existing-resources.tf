# Outputs for existing resources scenario

output "project_id" {
  description = "ID of the Azure DevOps project"
  value       = data.azuredevops_project.existing_project.id
}

output "project_name" {
  description = "Name of the Azure DevOps project"
  value       = data.azuredevops_project.existing_project.name
}

output "project_url" {
  description = "URL of the Azure DevOps project"
  value       = "${var.org_service_url}/${data.azuredevops_project.existing_project.name}"
}

output "repository_id" {
  description = "ID of the Git repository"
  value       = data.azuredevops_git_repository.existing_repo.id
}

output "repository_name" {
  description = "Name of the Git repository"
  value       = data.azuredevops_git_repository.existing_repo.name
}

output "repository_url" {
  description = "URL of the Git repository"
  value       = data.azuredevops_git_repository.existing_repo.remote_url
}

output "build_definition_id" {
  description = "ID of the build definition"
  value       = azuredevops_build_definition.build.id
}

output "build_pipeline_url" {
  description = "URL of the build pipeline"
  value       = "${var.org_service_url}/${data.azuredevops_project.existing_project.name}/_build?definitionId=${azuredevops_build_definition.build.id}"
}

output "release_pipeline_id" {
  description = "ID of the release pipeline"
  value       = azuredevops_build_definition.release_pipeline.id
}

output "release_pipeline_url" {
  description = "URL of the release pipeline"
  value       = "${var.org_service_url}/${data.azuredevops_project.existing_project.name}/_build?definitionId=${azuredevops_build_definition.release_pipeline.id}"
}

output "environments" {
  description = "Map of environment names to IDs"
  value = {
    for env in azuredevops_environment.environments :
    env.name => env.id
  }
}

output "variable_group_id" {
  description = "ID of the release variable group"
  value       = azuredevops_variable_group.release_vars.id
}

output "variable_group_name" {
  description = "Name of the release variable group"
  value       = azuredevops_variable_group.release_vars.name
}

output "service_connection_id" {
  description = "ID of the Azure service connection (if created)"
  value       = var.create_service_connection ? azuredevops_serviceendpoint_azurerm.azure_endpoint[0].id : null
}

output "service_connection_name" {
  description = "Name of the Azure service connection (if created)"
  value       = var.create_service_connection ? azuredevops_serviceendpoint_azurerm.azure_endpoint[0].service_endpoint_name : null
}
