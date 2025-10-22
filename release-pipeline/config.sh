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

# ==========================================
# Branch Filters Configuration
# ==========================================
# Configure which branches trigger which stages
# Multiple branches separated by comma (no spaces)

# Default branch for manual releases
DEFAULT_BRANCH="main"

# Development Stage - triggered by these branches
DEVELOPMENT_BRANCHES="dev1,dev2"

# Staging Stage - triggered by these branches
STAGING_BRANCHES="stage"

# Production Stage - triggered by these branches
PRODUCTION_BRANCHES="prod"

# ==========================================
# Deployment Scripts Configuration
# ==========================================
# Customize deployment scripts for each stage
# Use \n for newlines in scripts

# Development Stage Script
DEVELOPMENT_SCRIPT='#!/bin/bash
echo "=========================================="
echo "Starting Deployment to Development"
echo "=========================================="
echo "Server: $(hostname)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "Artifact location: $(System.DefaultWorkingDirectory)"
echo ""

# Add your deployment commands here
# Example:
# sudo systemctl stop myapp-dev
# sudo cp -r $(System.DefaultWorkingDirectory)/_MyApp/drop/* /var/www/dev/
# sudo chown -R www-data:www-data /var/www/dev/
# sudo systemctl start myapp-dev

echo "Deployment to Development completed successfully!"
echo "=========================================="'

# Staging Stage Script
STAGING_SCRIPT='#!/bin/bash
echo "=========================================="
echo "Starting Deployment to Staging"
echo "=========================================="
echo "Server: $(hostname)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "Artifact location: $(System.DefaultWorkingDirectory)"
echo ""

# Add your deployment commands here
# Example:
# sudo systemctl stop myapp-staging
# sudo cp -r $(System.DefaultWorkingDirectory)/_MyApp/drop/* /var/www/staging/
# sudo chown -R www-data:www-data /var/www/staging/
# sudo systemctl start myapp-staging

echo "Deployment to Staging completed successfully!"
echo "=========================================="'

# Production Stage Script
PRODUCTION_SCRIPT='#!/bin/bash
echo "=========================================="
echo "Starting Deployment to Production"
echo "=========================================="
echo "Server: $(hostname)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "Artifact location: $(System.DefaultWorkingDirectory)"
echo ""

# Add your deployment commands here
# Example:
# sudo systemctl stop myapp
# sudo cp -r $(System.DefaultWorkingDirectory)/_MyApp/drop/* /var/www/production/
# sudo chown -R www-data:www-data /var/www/production/
# sudo systemctl start myapp

echo "Deployment to Production completed successfully!"
echo "=========================================="'
