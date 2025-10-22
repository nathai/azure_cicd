output "project_id" {
  description = "ID of the Azure DevOps project"
  value       = azuredevops_project.project.id
}

output "project_url" {
  description = "URL of the Azure DevOps project"
  value       = "${var.org_service_url}/${azuredevops_project.project.name}"
}

output "repository_id" {
  description = "ID of the Git repository"
  value       = azuredevops_git_repository.repo.id
}

output "repository_url" {
  description = "URL of the Git repository"
  value       = azuredevops_git_repository.repo.remote_url
}

output "build_definition_id" {
  description = "ID of the build definition"
  value       = azuredevops_build_definition.build.id
}

output "release_pipeline_id" {
  description = "ID of the release pipeline"
  value       = azuredevops_build_definition.release_pipeline.id
}

output "release_pipeline_url" {
  description = "URL of the release pipeline"
  value       = "${var.org_service_url}/${azuredevops_project.project.name}/_build?definitionId=${azuredevops_build_definition.release_pipeline.id}"
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
