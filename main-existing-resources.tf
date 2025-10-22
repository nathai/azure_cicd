# Use this file when you want to use existing Azure DevOps project and repository
# This creates only pipelines, environments, and variable groups

# Data sources to reference existing resources
data "azuredevops_project" "existing_project" {
  name = var.project_name
}

data "azuredevops_git_repository" "existing_repo" {
  project_id = data.azuredevops_project.existing_project.id
  name       = var.repository_name
}

# Build Definition (CI Pipeline)
resource "azuredevops_build_definition" "build" {
  project_id = data.azuredevops_project.existing_project.id
  name       = var.build_pipeline_name

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = data.azuredevops_git_repository.existing_repo.id
    branch_name = var.default_branch
    yml_path    = var.build_pipeline_path
  }
}

# Environments for release stages
resource "azuredevops_environment" "environments" {
  for_each = { for env in var.environments : env.name => env }

  project_id  = data.azuredevops_project.existing_project.id
  name        = each.value.name
  description = "Deployment environment for ${each.value.name}"
}

# Variable Group for shared variables
resource "azuredevops_variable_group" "release_vars" {
  project_id   = data.azuredevops_project.existing_project.id
  name         = var.variable_group_name
  description  = "Shared variables for release pipeline"
  allow_access = true

  dynamic "variable" {
    for_each = var.pipeline_variables
    content {
      name         = variable.key
      value        = variable.value.is_secret ? null : variable.value.value
      secret_value = variable.value.is_secret ? variable.value.value : null
      is_secret    = variable.value.is_secret
    }
  }
}

# Release Pipeline using YAML
resource "azuredevops_build_definition" "release_pipeline" {
  project_id = data.azuredevops_project.existing_project.id
  name       = var.release_pipeline_name

  repository {
    repo_type   = "TfsGit"
    repo_id     = data.azuredevops_git_repository.existing_repo.id
    branch_name = var.default_branch
    yml_path    = var.release_pipeline_path
  }

  variable_groups = [
    azuredevops_variable_group.release_vars.id
  ]
}

# Optional: Service Endpoint for Azure deployments
resource "azuredevops_serviceendpoint_azurerm" "azure_endpoint" {
  count                 = var.create_service_connection ? 1 : 0
  project_id            = data.azuredevops_project.existing_project.id
  service_endpoint_name = var.service_connection_name
  description           = "Azure Service Connection managed by Terraform"

  credentials {
    serviceprincipalid  = var.azure_service_principal_id
    serviceprincipalkey = var.azure_service_principal_key
  }

  azurerm_spn_tenantid      = var.azure_tenant_id
  azurerm_subscription_id   = var.azure_subscription_id
  azurerm_subscription_name = var.azure_subscription_name
}

# Optional: Build Pipeline with specific queue
# Uncomment if you need to use a specific agent pool
# data "azuredevops_agent_pool" "pool" {
#   name = var.agent_pool_name
# }

# resource "azuredevops_agent_queue" "queue" {
#   project_id    = data.azuredevops_project.existing_project.id
#   agent_pool_id = data.azuredevops_agent_pool.pool.id
# }
