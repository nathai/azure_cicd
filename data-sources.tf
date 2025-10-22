# Data sources to reference existing Azure DevOps project and repository
# These resources must already exist in your Azure DevOps organization

data "azuredevops_project" "project" {
  name = var.project_name
}

data "azuredevops_git_repository" "repo" {
  project_id = data.azuredevops_project.project.id
  name       = var.repository_name
}
