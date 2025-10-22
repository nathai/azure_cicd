# Azure DevOps Connection
variable "org_service_url" {
  description = "Azure DevOps Organization URL (e.g., https://dev.azure.com/your-org)"
  type        = string
}

variable "personal_access_token" {
  description = "Azure DevOps Personal Access Token with appropriate permissions"
  type        = string
  sensitive   = true
}

# Existing Project and Repository
variable "project_name" {
  description = "Name of the EXISTING Azure DevOps project that contains the repository"
  type        = string
}

variable "repository_name" {
  description = "Name of the EXISTING Git repository in the project"
  type        = string
}

variable "pipeline_project_name" {
  description = "Name of the Azure DevOps project where pipelines will be created. If not specified, uses project_name (same as repository project)"
  type        = string
  default     = ""
}

variable "default_branch" {
  description = "Default branch for pipelines (e.g., refs/heads/main or refs/heads/master)"
  type        = string
  default     = "refs/heads/main"
}

# Build Pipeline Configuration
variable "build_pipeline_name" {
  description = "Name of the build (CI) pipeline"
  type        = string
  default     = "CI-Pipeline"
}

variable "build_pipeline_yaml_path" {
  description = "Path to the build pipeline YAML file in the repository"
  type        = string
  default     = "azure-pipelines.yml"
}

variable "build_use_variable_groups" {
  description = "Whether to link variable groups to build pipeline"
  type        = bool
  default     = true
}

# Release Pipeline Configuration
variable "release_pipeline_name" {
  description = "Name of the release (CD) pipeline"
  type        = string
  default     = "CD-Pipeline"
}

variable "release_pipeline_yaml_path" {
  description = "Path to the release pipeline YAML file in the repository"
  type        = string
  default     = "azure-release-pipeline.yml"
}

variable "release_use_variable_groups" {
  description = "Whether to link variable groups to release pipeline"
  type        = bool
  default     = true
}

# Variable Group Configuration
variable "create_variable_group" {
  description = "Whether to create a variable group"
  type        = bool
  default     = true
}

variable "variable_group_name" {
  description = "Name of the variable group"
  type        = string
  default     = "Pipeline-Variables"
}

variable "variable_group_description" {
  description = "Description of the variable group"
  type        = string
  default     = "Shared variables for CI/CD pipelines"
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

# Environment Configuration
variable "create_environments" {
  description = "Whether to create deployment environments"
  type        = bool
  default     = true
}

variable "environments" {
  description = "List of deployment environments to create"
  type = list(object({
    name = string
  }))
  default = [
    { name = "Development" },
    { name = "Staging" },
    { name = "Production" }
  ]
}
