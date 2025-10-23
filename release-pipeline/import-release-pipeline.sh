#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
ENV_FILE="${1:-pipelines.env}"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Azure DevOps Release Pipeline Import${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Show usage if help requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: $0 [ENV_FILE]"
    echo ""
    echo "Arguments:"
    echo "  ENV_FILE    Path to .env configuration file (default: pipelines.env)"
    echo ""
    echo "Examples:"
    echo "  $0                          # Uses pipelines.env"
    echo "  $0 my-app.env              # Uses my-app.env"
    echo "  $0 configs/production.env  # Uses configs/production.env"
    echo ""
    echo "First time setup:"
    echo "  1. Copy template: cp pipelines.env.example pipelines.env"
    echo "  2. Edit your values: nano pipelines.env"
    echo "  3. Run import: $0 pipelines.env"
    exit 0
fi

# Load configuration
if [ -f "$ENV_FILE" ]; then
    echo -e "${GREEN}Loading configuration from: ${ENV_FILE}${NC}"
    source "$ENV_FILE"
else
    echo -e "${RED}Error: Configuration file not found: ${ENV_FILE}${NC}"
    echo ""
    echo -e "${YELLOW}First time setup:${NC}"
    echo "  1. Copy template: ${YELLOW}cp pipelines.env.example pipelines.env${NC}"
    echo "  2. Edit your values: ${YELLOW}nano pipelines.env${NC}"
    echo "  3. Run import: ${YELLOW}$0 pipelines.env${NC}"
    echo ""
    echo "Or specify a different config file:"
    echo "  ${YELLOW}$0 my-custom.env${NC}"
    exit 1
fi

# Parse REPO_URL if provided (auto-extract organization, project, repo names)
if [ -n "$REPO_URL" ]; then
    echo -e "${BLUE}Parsing repository URL...${NC}"

    # Support both URL formats:
    # https://dev.azure.com/{org}/{project}/_git/{repo}
    # https://{org}.visualstudio.com/{project}/_git/{repo}

    if [[ "$REPO_URL" =~ https://dev\.azure\.com/([^/]+)/([^/]+)/_git/([^/]+) ]]; then
        ORGANIZATION_NAME="${BASH_REMATCH[1]}"
        REPO_PROJECT_NAME="${BASH_REMATCH[2]}"
        REPO_NAME="${BASH_REMATCH[3]}"
        echo -e "${GREEN}✓ Extracted from URL:${NC}"
        echo -e "${GREEN}  - Organization: ${ORGANIZATION_NAME}${NC}"
        echo -e "${GREEN}  - Project: ${REPO_PROJECT_NAME}${NC}"
        echo -e "${GREEN}  - Repository: ${REPO_NAME}${NC}"
    elif [[ "$REPO_URL" =~ https://([^.]+)\.visualstudio\.com/([^/]+)/_git/([^/]+) ]]; then
        ORGANIZATION_NAME="${BASH_REMATCH[1]}"
        REPO_PROJECT_NAME="${BASH_REMATCH[2]}"
        REPO_NAME="${BASH_REMATCH[3]}"
        echo -e "${GREEN}✓ Extracted from URL:${NC}"
        echo -e "${GREEN}  - Organization: ${ORGANIZATION_NAME}${NC}"
        echo -e "${GREEN}  - Project: ${REPO_PROJECT_NAME}${NC}"
        echo -e "${GREEN}  - Repository: ${REPO_NAME}${NC}"
    else
        echo -e "${RED}Error: Invalid repository URL format${NC}"
        echo -e "${RED}Expected format:${NC}"
        echo -e "${RED}  https://dev.azure.com/{org}/{project}/_git/{repo}${NC}"
        echo -e "${RED}  OR${NC}"
        echo -e "${RED}  https://{org}.visualstudio.com/{project}/_git/{repo}${NC}"
        exit 1
    fi
fi

# Set PIPELINE_PROJECT_NAME to REPO_PROJECT_NAME if not specified
if [ -z "$PIPELINE_PROJECT_NAME" ]; then
    PIPELINE_PROJECT_NAME="$REPO_PROJECT_NAME"
    echo -e "${BLUE}Pipeline project not specified, using repo project: ${PIPELINE_PROJECT_NAME}${NC}"
fi

# Validate required variables
if [ -z "$ORGANIZATION_NAME" ] || [ -z "$REPO_PROJECT_NAME" ] || [ -z "$AZURE_DEVOPS_PAT" ] || [ -z "$REPO_NAME" ]; then
    echo -e "${RED}Error: Missing required configuration!${NC}"
    echo -e "${RED}Please update config.local.sh with your values${NC}"
    exit 1
fi

# Base64 encode PAT for authentication
AUTH_HEADER="Authorization: Basic $(echo -n :$AZURE_DEVOPS_PAT | base64)"

echo ""
echo -e "${BLUE}Step 1: Fetching Repository Project ID...${NC}"
REPO_PROJECT_RESPONSE=$(curl -s -X GET \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  "https://dev.azure.com/${ORGANIZATION_NAME}/_apis/projects/${REPO_PROJECT_NAME}?api-version=7.1")

REPO_PROJECT_ID=$(echo $REPO_PROJECT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$REPO_PROJECT_ID" ]; then
    echo -e "${RED}Error: Could not fetch Repository Project ID${NC}"
    echo -e "${RED}Response: $REPO_PROJECT_RESPONSE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Repository Project: ${REPO_PROJECT_NAME}${NC}"
echo -e "${GREEN}✓ Repository Project ID: ${REPO_PROJECT_ID}${NC}"

echo ""
echo -e "${BLUE}Step 2: Fetching Pipeline Project ID...${NC}"

if [ "$PIPELINE_PROJECT_NAME" = "$REPO_PROJECT_NAME" ]; then
    PIPELINE_PROJECT_ID="$REPO_PROJECT_ID"
    echo -e "${GREEN}✓ Using same project for pipelines${NC}"
else
    PIPELINE_PROJECT_RESPONSE=$(curl -s -X GET \
      -H "$AUTH_HEADER" \
      -H "Content-Type: application/json" \
      "https://dev.azure.com/${ORGANIZATION_NAME}/_apis/projects/${PIPELINE_PROJECT_NAME}?api-version=7.1")

    PIPELINE_PROJECT_ID=$(echo $PIPELINE_PROJECT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

    if [ -z "$PIPELINE_PROJECT_ID" ]; then
        echo -e "${RED}Error: Could not fetch Pipeline Project ID${NC}"
        echo -e "${RED}Response: $PIPELINE_PROJECT_RESPONSE${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Pipeline Project: ${PIPELINE_PROJECT_NAME}${NC}"
echo -e "${GREEN}✓ Pipeline Project ID: ${PIPELINE_PROJECT_ID}${NC}"

echo ""
echo -e "${BLUE}Step 3: Fetching Repository ID...${NC}"
REPO_RESPONSE=$(curl -s -X GET \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  "https://dev.azure.com/${ORGANIZATION_NAME}/${REPO_PROJECT_NAME}/_apis/git/repositories/${REPO_NAME}?api-version=7.1")

REPO_ID=$(echo $REPO_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$REPO_ID" ]; then
    echo -e "${RED}Error: Could not fetch Repository ID${NC}"
    echo -e "${RED}Response: $REPO_RESPONSE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Repository: ${REPO_NAME}${NC}"
echo -e "${GREEN}✓ Repository ID: ${REPO_ID}${NC}"

echo ""
echo -e "${BLUE}Step 4: Validating Deployment Groups and Tags...${NC}"

if [ -z "$DEVELOPMENT_DEPLOYMENT_GROUP_ID" ] || [ -z "$STAGING_DEPLOYMENT_GROUP_ID" ] || [ -z "$PRODUCTION_DEPLOYMENT_GROUP_ID" ]; then
    echo -e "${YELLOW}Warning: Deployment Group IDs not configured${NC}"
    echo -e "${YELLOW}Please update config.local.sh with deployment group IDs${NC}"
    echo -e "${YELLOW}You can find them at:${NC}"
    echo -e "${YELLOW}https://dev.azure.com/${ORGANIZATION_NAME}/${PIPELINE_PROJECT_NAME}/_settings/agentqueues${NC}"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ Development Deployment Group ID: ${DEVELOPMENT_DEPLOYMENT_GROUP_ID}${NC}"
    echo -e "${GREEN}  Tags: ${DEVELOPMENT_TAGS}${NC}"
    echo -e "${GREEN}✓ Staging Deployment Group ID: ${STAGING_DEPLOYMENT_GROUP_ID}${NC}"
    echo -e "${GREEN}  Tags: ${STAGING_TAGS}${NC}"
    echo -e "${GREEN}✓ Production Deployment Group ID: ${PRODUCTION_DEPLOYMENT_GROUP_ID}${NC}"
    echo -e "${GREEN}  Tags: ${PRODUCTION_TAGS}${NC}"
fi

echo ""
echo -e "${BLUE}Step 5: Preparing release definition...${NC}"

# Function to convert comma-separated branches to JSON trigger conditions
branches_to_json() {
    local branches="$1"
    local result="["
    local first=true

    IFS=',' read -ra BRANCH_ARRAY <<< "$branches"
    for branch in "${BRANCH_ARRAY[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            result="$result,"
        fi
        result="$result{\"sourceBranch\":\"$branch\",\"tags\":[],\"useBuildDefinitionBranch\":false,\"createReleaseOnBuildTagging\":false}"
    done

    result="$result]"
    echo "$result"
}

# Convert branches to JSON trigger conditions
DEVELOPMENT_BRANCHES_JSON=$(branches_to_json "$DEVELOPMENT_BRANCHES")
STAGING_BRANCHES_JSON=$(branches_to_json "$STAGING_BRANCHES")
PRODUCTION_BRANCHES_JSON=$(branches_to_json "$PRODUCTION_BRANCHES")

echo -e "${GREEN}✓ Branch triggers configured:${NC}"
echo -e "${GREEN}  - Development: ${DEVELOPMENT_BRANCHES}${NC}"
echo -e "${GREEN}  - Staging: ${STAGING_BRANCHES}${NC}"
echo -e "${GREEN}  - Production: ${PRODUCTION_BRANCHES}${NC}"

# Read JSON template
JSON_TEMPLATE=$(cat release-definition.json)

# Convert comma-separated tags to JSON array format
DEVELOPMENT_TAGS_JSON=$(echo "$DEVELOPMENT_TAGS" | sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/')
STAGING_TAGS_JSON=$(echo "$STAGING_TAGS" | sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/')
PRODUCTION_TAGS_JSON=$(echo "$PRODUCTION_TAGS" | sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/')

# Escape scripts for JSON (escape newlines, quotes, backslashes)
DEVELOPMENT_SCRIPT_ESCAPED=$(echo "$DEVELOPMENT_SCRIPT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')
STAGING_SCRIPT_ESCAPED=$(echo "$STAGING_SCRIPT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')
PRODUCTION_SCRIPT_ESCAPED=$(echo "$PRODUCTION_SCRIPT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# Escape again for sed replacement context (double-escape backslashes and escape &)
DEVELOPMENT_SCRIPT_FOR_SED=$(printf '%s' "$DEVELOPMENT_SCRIPT_ESCAPED" | sed 's/\\/\\\\/g; s/&/\\&/g')
STAGING_SCRIPT_FOR_SED=$(printf '%s' "$STAGING_SCRIPT_ESCAPED" | sed 's/\\/\\\\/g; s/&/\\&/g')
PRODUCTION_SCRIPT_FOR_SED=$(printf '%s' "$PRODUCTION_SCRIPT_ESCAPED" | sed 's/\\/\\\\/g; s/&/\\&/g')

# Replace placeholders
JSON_DEFINITION=$(echo "$JSON_TEMPLATE" | \
  sed "s/<PIPELINE_NAME>/$PIPELINE_NAME/g" | \
  sed "s/<REPO_PROJECT_ID>/$REPO_PROJECT_ID/g" | \
  sed "s/<REPO_PROJECT_NAME>/$REPO_PROJECT_NAME/g" | \
  sed "s/<PIPELINE_PROJECT_ID>/$PIPELINE_PROJECT_ID/g" | \
  sed "s/<PIPELINE_PROJECT_NAME>/$PIPELINE_PROJECT_NAME/g" | \
  sed "s/<REPO_ID>/$REPO_ID/g" | \
  sed "s/<REPO_NAME>/$REPO_NAME/g" | \
  sed "s/<DEFAULT_BRANCH>/$DEFAULT_BRANCH/g" | \
  sed "s|<DEVELOPMENT_BRANCHES_JSON>|$DEVELOPMENT_BRANCHES_JSON|g" | \
  sed "s|<STAGING_BRANCHES_JSON>|$STAGING_BRANCHES_JSON|g" | \
  sed "s|<PRODUCTION_BRANCHES_JSON>|$PRODUCTION_BRANCHES_JSON|g" | \
  sed "s/<DEVELOPMENT_DEPLOYMENT_GROUP_ID>/$DEVELOPMENT_DEPLOYMENT_GROUP_ID/g" | \
  sed "s|<DEVELOPMENT_TAGS>|$DEVELOPMENT_TAGS_JSON|g" | \
  sed "s|<DEVELOPMENT_SCRIPT>|$DEVELOPMENT_SCRIPT_FOR_SED|g" | \
  sed "s/<STAGING_DEPLOYMENT_GROUP_ID>/$STAGING_DEPLOYMENT_GROUP_ID/g" | \
  sed "s|<STAGING_TAGS>|$STAGING_TAGS_JSON|g" | \
  sed "s|<STAGING_SCRIPT>|$STAGING_SCRIPT_FOR_SED|g" | \
  sed "s/<PRODUCTION_DEPLOYMENT_GROUP_ID>/$PRODUCTION_DEPLOYMENT_GROUP_ID/g" | \
  sed "s|<PRODUCTION_TAGS>|$PRODUCTION_TAGS_JSON|g" | \
  sed "s|<PRODUCTION_SCRIPT>|$PRODUCTION_SCRIPT_FOR_SED|g")

# Save processed JSON
echo "$JSON_DEFINITION" > release-definition.processed.json
echo -e "${GREEN}✓ Processed definition saved to: release-definition.processed.json${NC}"

echo ""
echo -e "${BLUE}Step 6: Importing release pipeline into ${PIPELINE_PROJECT_NAME}...${NC}"

IMPORT_RESPONSE=$(curl -s -X POST \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$JSON_DEFINITION" \
  "https://vsrm.dev.azure.com/${ORGANIZATION_NAME}/${PIPELINE_PROJECT_NAME}/_apis/release/definitions?api-version=7.1")

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
echo -e "${GREEN}Release Pipeline ID: ${RELEASE_ID}${NC}"
echo -e "${GREEN}Pipeline Name: Multi-Stage Auto Release${NC}"
echo ""
echo -e "${BLUE}Pipeline Details:${NC}"
echo -e "${BLUE}  - Created in: ${PIPELINE_PROJECT_NAME}${NC}"
echo -e "${BLUE}  - Source repo: ${REPO_PROJECT_NAME}/${REPO_NAME}${NC}"
echo ""
echo -e "${BLUE}View your pipeline at:${NC}"
echo -e "${BLUE}https://dev.azure.com/${ORGANIZATION_NAME}/${PIPELINE_PROJECT_NAME}/_release?definitionId=${RELEASE_ID}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${YELLOW}1. Tag servers in deployment groups with appropriate tags:${NC}"
echo -e "${YELLOW}   - Development: ${DEVELOPMENT_TAGS}${NC}"
echo -e "${YELLOW}   - Staging: ${STAGING_TAGS}${NC}"
echo -e "${YELLOW}   - Production: ${PRODUCTION_TAGS}${NC}"
echo -e "${YELLOW}2. Test the pipeline by pushing to configured branches:${NC}"
echo -e "${YELLOW}   - Development: ${DEVELOPMENT_BRANCHES}${NC}"
echo -e "${YELLOW}   - Staging: ${STAGING_BRANCHES}${NC}"
echo -e "${YELLOW}   - Production: ${PRODUCTION_BRANCHES}${NC}"
echo -e "${YELLOW}3. Customize deployment scripts in config file as needed${NC}"
echo ""
