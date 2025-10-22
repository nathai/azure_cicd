# Data sources to reference existing Azure DevOps projects and repository
# These resources must already exist in your Azure DevOps organization

# Project that contains the repository
data "azuredevops_project" "repo_project" {
  name = var.project_name
}

# Project where pipelines will be created
# If pipeline_project_name is not specified, uses the same project as repository
data "azuredevops_project" "pipeline_project" {
  name = var.pipeline_project_name != "" ? var.pipeline_project_name : var.project_name
}

# Git repository (in the repo project)
data "azuredevops_git_repository" "repo" {
  project_id = data.azuredevops_project.repo_project.id
  name       = var.repository_name
}
