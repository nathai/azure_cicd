# Deployment Environments
# These environments are used in YAML pipelines for deployment stages
# Environments are created in the same project as the pipelines

resource "azuredevops_environment" "envs" {
  for_each = var.create_environments ? { for env in var.environments : env.name => env } : {}

  project_id  = data.azuredevops_project.pipeline_project.id
  name        = each.value.name
  description = "Deployment environment for ${each.value.name}"
}

# Optional: Environment approvals and checks
# Note: Approvals are better managed through Azure DevOps UI or via API
# Terraform provider has limited support for approval configurations
