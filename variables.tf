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
