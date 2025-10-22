#!/bin/bash
# Configuration file for Azure DevOps Release Pipeline Import
# Copy this file to config.local.sh and fill in your values
# config.local.sh is ignored by git

# Azure DevOps Organization
ORGANIZATION_NAME="your-org-name"

# Repository Project (project that contains the source code repository)
REPO_PROJECT_NAME="YourRepoProjectName"

# Pipeline Project (project where the release pipeline will be created)
# If empty, will use the same project as repository (REPO_PROJECT_NAME)
PIPELINE_PROJECT_NAME=""  # Optional: "YourPipelineProjectName"

# Personal Access Token (PAT) - Keep this secure!
# Create PAT at: https://dev.azure.com/{org}/_usersSettings/tokens
# Required scopes:
#   - Release (Read, write, execute & manage)
#   - Code (Read) - if accessing repo from different project
AZURE_DEVOPS_PAT="your-pat-token-here"

# Repository Configuration
REPO_NAME="your-repo-name"

# Project and Repository IDs (will be fetched automatically)
# Leave these empty - script will populate them
REPO_PROJECT_ID=""
PIPELINE_PROJECT_ID=""
REPO_ID=""

# Deployment Group Configuration
# You must create deployment groups first in the PIPELINE project
# Get IDs from: https://dev.azure.com/{org}/{pipeline-project}/_settings/agentqueues?queueId={id}&view=agents

# Development Stage
DEVELOPMENT_DEPLOYMENT_GROUP_ID=""
DEVELOPMENT_TAGS="web-server,dev"  # Comma-separated tags to target specific servers

# Staging Stage
STAGING_DEPLOYMENT_GROUP_ID=""
STAGING_TAGS="web-server,staging"  # Comma-separated tags

# Production Stage
PRODUCTION_DEPLOYMENT_GROUP_ID=""
PRODUCTION_TAGS="web-server,production"  # Comma-separated tags
