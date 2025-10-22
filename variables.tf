variable "org_service_url" {
  description = "Azure DevOps Organization URL (e.g., https://dev.azure.com/your-org)"
  type        = string
}

variable "personal_access_token" {
  description = "Azure DevOps Personal Access Token with appropriate permissions"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Name of the Azure DevOps project"
  type        = string
}

variable "project_description" {
  description = "Description of the Azure DevOps project"
  type        = string
  default     = "Project managed by Terraform"
}

variable "repository_name" {
  description = "Name of the Git repository"
  type        = string
}

variable "release_pipeline_name" {
  description = "Name of the release pipeline"
  type        = string
  default     = "Release Pipeline"
}

variable "environments" {
  description = "List of deployment environments"
  type = list(object({
    name     = string
    order    = number
    approvers = list(string)
  }))
  default = [
    {
      name     = "Development"
      order    = 1
      approvers = []
    },
    {
      name     = "Staging"
      order    = 2
      approvers = []
    },
    {
      name     = "Production"
      order    = 3
      approvers = []
    }
  ]
}

variable "service_connection_name" {
  description = "Name of the Azure service connection"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Additional variables for existing resources scenario
variable "build_pipeline_name" {
  description = "Name of the build (CI) pipeline"
  type        = string
  default     = "CI Pipeline"
}

variable "default_branch" {
  description = "Default branch for pipelines"
  type        = string
  default     = "refs/heads/main"
}

variable "build_pipeline_path" {
  description = "Path to the build pipeline YAML file in the repository"
  type        = string
  default     = "azure-pipelines.yml"
}

variable "release_pipeline_path" {
  description = "Path to the release pipeline YAML file in the repository"
  type        = string
  default     = "azure-release-pipeline.yml"
}

variable "variable_group_name" {
  description = "Name of the variable group"
  type        = string
  default     = "Release-Variables"
}

variable "pipeline_variables" {
  description = "Variables to add to the variable group"
  type = map(object({
    value     = string
    is_secret = bool
  }))
  default = {
    environment = {
      value     = "default"
      is_secret = false
    }
  }
}

# Azure Service Connection variables (optional)
variable "create_service_connection" {
  description = "Whether to create Azure service connection"
  type        = bool
  default     = false
}

variable "azure_service_principal_id" {
  description = "Azure Service Principal ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_service_principal_key" {
  description = "Azure Service Principal Key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  default     = ""
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = ""
}

variable "azure_subscription_name" {
  description = "Azure Subscription Name"
  type        = string
  default     = ""
}

variable "agent_pool_name" {
  description = "Name of the agent pool to use"
  type        = string
  default     = "Azure Pipelines"
}
