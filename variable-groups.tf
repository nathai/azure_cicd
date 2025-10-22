# Variable Group
# Shared variables accessible by both build and release pipelines
# Variable groups are created in the same project as the pipelines

resource "azuredevops_variable_group" "pipeline_vars" {
  count = var.create_variable_group ? 1 : 0

  project_id   = data.azuredevops_project.pipeline_project.id
  name         = var.variable_group_name
  description  = var.variable_group_description
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
