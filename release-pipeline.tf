# Release Pipeline (CD)
# This creates a CD pipeline for deployments across environments

resource "azuredevops_build_definition" "release" {
  project_id = data.azuredevops_project.project.id
  name       = var.release_pipeline_name

  # Repository configuration
  repository {
    repo_type   = "TfsGit"
    repo_id     = data.azuredevops_git_repository.repo.id
    branch_name = var.default_branch
    yml_path    = var.release_pipeline_yaml_path
  }

  # Link to variable groups
  variable_groups = var.release_use_variable_groups ? [azuredevops_variable_group.pipeline_vars.id] : []

  # Optional: Pull request trigger
  # Uncomment if you want to trigger on PRs
  # pull_request_trigger {
  #   use_yaml = true
  # }
}

# Optional: Release pipeline variables (inline)
# Uncomment and customize if you need pipeline-specific variables
# resource "azuredevops_build_definition_variable" "release_vars" {
#   for_each = var.release_pipeline_variables
#
#   project_id   = data.azuredevops_project.project.id
#   definition_id = azuredevops_build_definition.release.id
#   name         = each.key
#   value        = each.value.value
#   is_secret    = each.value.is_secret
# }
