#!/bin/bash
# Configuration file for Azure DevOps Release Pipeline Import
# Copy this file to config.local.sh and fill in your values
# config.local.sh is ignored by git

# Azure DevOps Organization and Project
ORGANIZATION_NAME="your-org-name"
PROJECT_NAME="YourProjectName"

# Personal Access Token (PAT) - Keep this secure!
# Create PAT at: https://dev.azure.com/{org}/_usersSettings/tokens
# Required scopes: Release (Read, write, execute & manage)
AZURE_DEVOPS_PAT="your-pat-token-here"

# Repository Configuration
REPO_NAME="your-repo-name"

# Get Project and Repository IDs (will be fetched automatically)
# Leave these empty - script will populate them
PROJECT_ID=""
REPO_ID=""

# Deployment Group IDs
# You must create deployment groups first, then get their IDs
# Get IDs from: https://dev.azure.com/{org}/{project}/_settings/agentqueues?queueId={id}&view=agents
DEVELOPMENT_DEPLOYMENT_GROUP_ID=""
STAGING_DEPLOYMENT_GROUP_ID=""
PRODUCTION_DEPLOYMENT_GROUP_ID=""
