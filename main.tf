# Azure DevOps Project
resource "azuredevops_project" "project" {
  name               = var.project_name
  description        = var.project_description
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"

  features = {
    "boards"       = "enabled"
    "repositories" = "enabled"
    "pipelines"    = "enabled"
    "testplans"    = "disabled"
    "artifacts"    = "enabled"
  }
}

# Git Repository
resource "azuredevops_git_repository" "repo" {
  project_id = azuredevops_project.project.id
  name       = var.repository_name
  initialization {
    init_type = "Clean"
  }
}

# Build Definition (required for release pipeline)
resource "azuredevops_build_definition" "build" {
  project_id = azuredevops_project.project.id
  name       = "${var.repository_name}-CI"

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.repo.id
    branch_name = azuredevops_git_repository.repo.default_branch
    yml_path    = "azure-pipelines.yml"
  }
}

# Environments for release stages
resource "azuredevops_environment" "environments" {
  for_each = { for env in var.environments : env.name => env }

  project_id  = azuredevops_project.project.id
  name        = each.value.name
  description = "Deployment environment for ${each.value.name}"
}

# Variable Group for shared variables
resource "azuredevops_variable_group" "release_vars" {
  project_id   = azuredevops_project.project.id
  name         = "Release-Variables"
  description  = "Shared variables for release pipeline"
  allow_access = true

  variable {
    name  = "environment"
    value = "default"
  }

  variable {
    name      = "api_key"
    secret_value = "placeholder-secret"
    is_secret = true
  }
}

# Release Pipeline using YAML (Modern approach)
# Note: Azure DevOps is moving towards YAML-based release pipelines
# Create a sample YAML pipeline file
resource "azuredevops_build_definition" "release_pipeline" {
  project_id = azuredevops_project.project.id
  name       = var.release_pipeline_name

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.repo.id
    branch_name = azuredevops_git_repository.repo.default_branch
    yml_path    = "azure-release-pipeline.yml"
  }

  variable_groups = [
    azuredevops_variable_group.release_vars.id
  ]
}

# Service Endpoint (if needed for Azure deployments)
# Uncomment and configure if you need Azure service connection
# resource "azuredevops_serviceendpoint_azurerm" "azure_endpoint" {
#   count               = var.service_connection_name != "" ? 1 : 0
#   project_id          = azuredevops_project.project.id
#   service_endpoint_name = var.service_connection_name
#   description         = "Azure Service Connection managed by Terraform"
#
#   credentials {
#     serviceprincipalid  = var.azure_service_principal_id
#     serviceprincipalkey = var.azure_service_principal_key
#   }
#
#   azurerm_spn_tenantid      = var.azure_tenant_id
#   azurerm_subscription_id   = var.azure_subscription_id
#   azurerm_subscription_name = var.azure_subscription_name
# }

# Agent Pool (optional - use if you need custom agents)
# resource "azuredevops_agent_pool" "pool" {
#   name           = "Custom-Agent-Pool"
#   auto_provision = false
#   auto_update    = true
# }

# Agent Queue
# resource "azuredevops_agent_queue" "queue" {
#   project_id    = azuredevops_project.project.id
#   agent_pool_id = azuredevops_agent_pool.pool.id
# }
