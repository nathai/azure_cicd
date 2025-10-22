# Build Pipeline (CI)
# This creates a CI pipeline that runs on code changes
# Pipeline is created in pipeline_project, but references repository from repo_project

resource "azuredevops_build_definition" "build" {
  project_id = data.azuredevops_project.pipeline_project.id
  name       = var.build_pipeline_name

  # CI Trigger configuration
  ci_trigger {
    use_yaml = true
  }

  # Repository configuration
  repository {
    repo_type   = "TfsGit"
    repo_id     = data.azuredevops_git_repository.repo.id
    branch_name = var.default_branch
    yml_path    = var.build_pipeline_yaml_path
  }

  # Optional: Link to variable groups
  variable_groups = var.build_use_variable_groups ? [azuredevops_variable_group.pipeline_vars.id] : []
}

# Optional: Build pipeline variables (inline)
# Uncomment and customize if you need pipeline-specific variables
# resource "azuredevops_build_definition_variable" "build_vars" {
#   for_each = var.build_pipeline_variables
#
#   project_id   = data.azuredevops_project.pipeline_project.id
#   definition_id = azuredevops_build_definition.build.id
#   name         = each.key
#   value        = each.value.value
#   is_secret    = each.value.is_secret
# }
