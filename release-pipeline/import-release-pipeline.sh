#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Azure DevOps Release Pipeline Import${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Load configuration
if [ -f "config.local.sh" ]; then
    echo -e "${GREEN}Loading configuration from config.local.sh...${NC}"
    source config.local.sh
elif [ -f "config.sh" ]; then
    echo -e "${YELLOW}Warning: Using default config.sh${NC}"
    echo -e "${YELLOW}Please copy config.sh to config.local.sh and update values${NC}"
    source config.sh
else
    echo -e "${RED}Error: No configuration file found!${NC}"
    echo -e "${RED}Please create config.local.sh from config.sh${NC}"
    exit 1
fi

# Validate required variables
if [ -z "$ORGANIZATION_NAME" ] || [ -z "$PROJECT_NAME" ] || [ -z "$AZURE_DEVOPS_PAT" ] || [ -z "$REPO_NAME" ]; then
    echo -e "${RED}Error: Missing required configuration!${NC}"
    echo -e "${RED}Please update config.local.sh with your values${NC}"
    exit 1
fi

# Base64 encode PAT for authentication
AUTH_HEADER="Authorization: Basic $(echo -n :$AZURE_DEVOPS_PAT | base64)"

echo ""
echo -e "${BLUE}Step 1: Fetching Project ID...${NC}"
PROJECT_RESPONSE=$(curl -s -X GET \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  "https://dev.azure.com/${ORGANIZATION_NAME}/_apis/projects/${PROJECT_NAME}?api-version=7.1")

PROJECT_ID=$(echo $PROJECT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: Could not fetch Project ID${NC}"
    echo -e "${RED}Response: $PROJECT_RESPONSE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Project ID: $PROJECT_ID${NC}"

echo ""
echo -e "${BLUE}Step 2: Fetching Repository ID...${NC}"
REPO_RESPONSE=$(curl -s -X GET \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  "https://dev.azure.com/${ORGANIZATION_NAME}/${PROJECT_NAME}/_apis/git/repositories/${REPO_NAME}?api-version=7.1")

REPO_ID=$(echo $REPO_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$REPO_ID" ]; then
    echo -e "${RED}Error: Could not fetch Repository ID${NC}"
    echo -e "${RED}Response: $REPO_RESPONSE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Repository ID: $REPO_ID${NC}"

echo ""
echo -e "${BLUE}Step 3: Validating Deployment Groups...${NC}"

if [ -z "$DEVELOPMENT_DEPLOYMENT_GROUP_ID" ] || [ -z "$STAGING_DEPLOYMENT_GROUP_ID" ] || [ -z "$PRODUCTION_DEPLOYMENT_GROUP_ID" ]; then
    echo -e "${YELLOW}Warning: Deployment Group IDs not configured${NC}"
    echo -e "${YELLOW}Please update config.local.sh with deployment group IDs${NC}"
    echo -e "${YELLOW}You can find them at:${NC}"
    echo -e "${YELLOW}https://dev.azure.com/${ORGANIZATION_NAME}/${PROJECT_NAME}/_settings/agentqueues${NC}"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ Development Deployment Group ID: $DEVELOPMENT_DEPLOYMENT_GROUP_ID${NC}"
    echo -e "${GREEN}✓ Staging Deployment Group ID: $STAGING_DEPLOYMENT_GROUP_ID${NC}"
    echo -e "${GREEN}✓ Production Deployment Group ID: $PRODUCTION_DEPLOYMENT_GROUP_ID${NC}"
fi

echo ""
echo -e "${BLUE}Step 4: Preparing release definition...${NC}"

# Read JSON template
JSON_TEMPLATE=$(cat release-definition.json)

# Replace placeholders
JSON_DEFINITION=$(echo "$JSON_TEMPLATE" | \
  sed "s/<PROJECT_ID>/$PROJECT_ID/g" | \
  sed "s/<PROJECT_NAME>/$PROJECT_NAME/g" | \
  sed "s/<REPO_ID>/$REPO_ID/g" | \
  sed "s/<REPO_NAME>/$REPO_NAME/g" | \
  sed "s/<DEVELOPMENT_DEPLOYMENT_GROUP_ID>/$DEVELOPMENT_DEPLOYMENT_GROUP_ID/g" | \
  sed "s/<STAGING_DEPLOYMENT_GROUP_ID>/$STAGING_DEPLOYMENT_GROUP_ID/g" | \
  sed "s/<PRODUCTION_DEPLOYMENT_GROUP_ID>/$PRODUCTION_DEPLOYMENT_GROUP_ID/g")

# Save processed JSON
echo "$JSON_DEFINITION" > release-definition.processed.json
echo -e "${GREEN}✓ Processed definition saved to: release-definition.processed.json${NC}"

echo ""
echo -e "${BLUE}Step 5: Importing release pipeline...${NC}"

IMPORT_RESPONSE=$(curl -s -X POST \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$JSON_DEFINITION" \
  "https://vsrm.dev.azure.com/${ORGANIZATION_NAME}/${PROJECT_NAME}/_apis/release/definitions?api-version=7.1")

# Check if import was successful
RELEASE_ID=$(echo $IMPORT_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$RELEASE_ID" ]; then
    echo -e "${RED}Error: Failed to import release pipeline${NC}"
    echo -e "${RED}Response:${NC}"
    echo "$IMPORT_RESPONSE" | jq '.' 2>/dev/null || echo "$IMPORT_RESPONSE"
    exit 1
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}✓ Success!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Release Pipeline ID: $RELEASE_ID${NC}"
echo -e "${GREEN}Pipeline Name: Multi-Stage Auto Release${NC}"
echo ""
echo -e "${BLUE}View your pipeline at:${NC}"
echo -e "${BLUE}https://dev.azure.com/${ORGANIZATION_NAME}/${PROJECT_NAME}/_release?definitionId=${RELEASE_ID}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${YELLOW}1. Configure deployment group IDs if not done${NC}"
echo -e "${YELLOW}2. Set up deployment group agents on target servers${NC}"
echo -e "${YELLOW}3. Test the pipeline by pushing to dev1 or dev2 branches${NC}"
echo ""
