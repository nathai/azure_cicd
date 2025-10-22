# Azure DevOps Release Pipeline Import Script (PowerShell)
# Requires PowerShell 5.1 or later

param(
    [string]$ConfigFile = "config.local.ps1"
)

Write-Host "=====================================" -ForegroundColor Blue
Write-Host "Azure DevOps Release Pipeline Import" -ForegroundColor Blue
Write-Host "=====================================" -ForegroundColor Blue
Write-Host ""

# Load configuration
if (Test-Path $ConfigFile) {
    Write-Host "Loading configuration from $ConfigFile..." -ForegroundColor Green
    . .\$ConfigFile
} elseif (Test-Path "config.ps1") {
    Write-Host "Warning: Using default config.ps1" -ForegroundColor Yellow
    Write-Host "Please copy config.ps1 to config.local.ps1 and update values" -ForegroundColor Yellow
    . .\config.ps1
} else {
    Write-Host "Error: No configuration file found!" -ForegroundColor Red
    Write-Host "Please create config.local.ps1 from config.ps1" -ForegroundColor Red
    exit 1
}

# Set PIPELINE_PROJECT_NAME to REPO_PROJECT_NAME if not specified
if ([string]::IsNullOrEmpty($PIPELINE_PROJECT_NAME)) {
    $PIPELINE_PROJECT_NAME = $REPO_PROJECT_NAME
    Write-Host "Pipeline project not specified, using repo project: $PIPELINE_PROJECT_NAME" -ForegroundColor Blue
}

# Validate required variables
if ([string]::IsNullOrEmpty($ORGANIZATION_NAME) -or
    [string]::IsNullOrEmpty($REPO_PROJECT_NAME) -or
    [string]::IsNullOrEmpty($AZURE_DEVOPS_PAT) -or
    [string]::IsNullOrEmpty($REPO_NAME)) {
    Write-Host "Error: Missing required configuration!" -ForegroundColor Red
    Write-Host "Please update config.local.ps1 with your values" -ForegroundColor Red
    exit 1
}

# Base64 encode PAT for authentication
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($AZURE_DEVOPS_PAT)"))
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    "Content-Type" = "application/json"
}

Write-Host ""
Write-Host "Step 1: Fetching Repository Project ID..." -ForegroundColor Blue

try {
    $repoProjectUrl = "https://dev.azure.com/$ORGANIZATION_NAME/_apis/projects/$REPO_PROJECT_NAME`?api-version=7.1"
    $repoProjectResponse = Invoke-RestMethod -Uri $repoProjectUrl -Method Get -Headers $headers
    $REPO_PROJECT_ID = $repoProjectResponse.id

    if ([string]::IsNullOrEmpty($REPO_PROJECT_ID)) {
        throw "Could not fetch Repository Project ID"
    }

    Write-Host "✓ Repository Project: $REPO_PROJECT_NAME" -ForegroundColor Green
    Write-Host "✓ Repository Project ID: $REPO_PROJECT_ID" -ForegroundColor Green
} catch {
    Write-Host "Error: Could not fetch Repository Project ID" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Fetching Pipeline Project ID..." -ForegroundColor Blue

try {
    if ($PIPELINE_PROJECT_NAME -eq $REPO_PROJECT_NAME) {
        $PIPELINE_PROJECT_ID = $REPO_PROJECT_ID
        Write-Host "✓ Using same project for pipelines" -ForegroundColor Green
    } else {
        $pipelineProjectUrl = "https://dev.azure.com/$ORGANIZATION_NAME/_apis/projects/$PIPELINE_PROJECT_NAME`?api-version=7.1"
        $pipelineProjectResponse = Invoke-RestMethod -Uri $pipelineProjectUrl -Method Get -Headers $headers
        $PIPELINE_PROJECT_ID = $pipelineProjectResponse.id

        if ([string]::IsNullOrEmpty($PIPELINE_PROJECT_ID)) {
            throw "Could not fetch Pipeline Project ID"
        }
    }

    Write-Host "✓ Pipeline Project: $PIPELINE_PROJECT_NAME" -ForegroundColor Green
    Write-Host "✓ Pipeline Project ID: $PIPELINE_PROJECT_ID" -ForegroundColor Green
} catch {
    Write-Host "Error: Could not fetch Pipeline Project ID" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 3: Fetching Repository ID..." -ForegroundColor Blue

try {
    $repoUrl = "https://dev.azure.com/$ORGANIZATION_NAME/$REPO_PROJECT_NAME/_apis/git/repositories/$REPO_NAME`?api-version=7.1"
    $repoResponse = Invoke-RestMethod -Uri $repoUrl -Method Get -Headers $headers
    $REPO_ID = $repoResponse.id

    if ([string]::IsNullOrEmpty($REPO_ID)) {
        throw "Could not fetch Repository ID"
    }

    Write-Host "✓ Repository: $REPO_NAME" -ForegroundColor Green
    Write-Host "✓ Repository ID: $REPO_ID" -ForegroundColor Green
} catch {
    Write-Host "Error: Could not fetch Repository ID" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 4: Validating Deployment Groups and Tags..." -ForegroundColor Blue

if ([string]::IsNullOrEmpty($DEVELOPMENT_DEPLOYMENT_GROUP_ID) -or
    [string]::IsNullOrEmpty($STAGING_DEPLOYMENT_GROUP_ID) -or
    [string]::IsNullOrEmpty($PRODUCTION_DEPLOYMENT_GROUP_ID)) {
    Write-Host "Warning: Deployment Group IDs not configured" -ForegroundColor Yellow
    Write-Host "Please update config.local.ps1 with deployment group IDs" -ForegroundColor Yellow
    Write-Host "You can find them at:" -ForegroundColor Yellow
    Write-Host "https://dev.azure.com/$ORGANIZATION_NAME/$PIPELINE_PROJECT_NAME/_settings/agentqueues" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        exit 1
    }
} else {
    Write-Host "✓ Development Deployment Group ID: $DEVELOPMENT_DEPLOYMENT_GROUP_ID" -ForegroundColor Green
    Write-Host "  Tags: $DEVELOPMENT_TAGS" -ForegroundColor Green
    Write-Host "✓ Staging Deployment Group ID: $STAGING_DEPLOYMENT_GROUP_ID" -ForegroundColor Green
    Write-Host "  Tags: $STAGING_TAGS" -ForegroundColor Green
    Write-Host "✓ Production Deployment Group ID: $PRODUCTION_DEPLOYMENT_GROUP_ID" -ForegroundColor Green
    Write-Host "  Tags: $PRODUCTION_TAGS" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 5: Preparing release definition..." -ForegroundColor Blue

# Function to convert comma-separated branches to JSON trigger conditions
function Convert-BranchesToJson {
    param([string]$branches)

    $branchArray = $branches -split ','
    $triggerConditions = @()

    foreach ($branch in $branchArray) {
        $triggerConditions += @{
            sourceBranch = $branch.Trim()
            tags = @()
            useBuildDefinitionBranch = $false
            createReleaseOnBuildTagging = $false
        }
    }

    return ($triggerConditions | ConvertTo-Json -Depth 10 -Compress)
}

# Convert branches to JSON trigger conditions
$developmentBranchesJson = Convert-BranchesToJson -branches $DEVELOPMENT_BRANCHES
$stagingBranchesJson = Convert-BranchesToJson -branches $STAGING_BRANCHES
$productionBranchesJson = Convert-BranchesToJson -branches $PRODUCTION_BRANCHES

Write-Host "✓ Branch triggers configured:" -ForegroundColor Green
Write-Host "  - Development: $DEVELOPMENT_BRANCHES" -ForegroundColor Green
Write-Host "  - Staging: $STAGING_BRANCHES" -ForegroundColor Green
Write-Host "  - Production: $PRODUCTION_BRANCHES" -ForegroundColor Green

# Read JSON template
$jsonTemplate = Get-Content -Path "release-definition.json" -Raw

# Convert comma-separated tags to JSON array format
$developmentTagsJson = '["' + ($DEVELOPMENT_TAGS -replace ',','","') + '"]'
$stagingTagsJson = '["' + ($STAGING_TAGS -replace ',','","') + '"]'
$productionTagsJson = '["' + ($PRODUCTION_TAGS -replace ',','","') + '"]'

# Escape scripts for JSON (escape backslashes first, then quotes, then add newlines)
$developmentScriptEscaped = $DEVELOPMENT_SCRIPT -replace '\\','\\' -replace '"','\"' -replace "`r`n","\n" -replace "`n","\n"
$stagingScriptEscaped = $STAGING_SCRIPT -replace '\\','\\' -replace '"','\"' -replace "`r`n","\n" -replace "`n","\n"
$productionScriptEscaped = $PRODUCTION_SCRIPT -replace '\\','\\' -replace '"','\"' -replace "`r`n","\n" -replace "`n","\n"

# Replace placeholders
$jsonDefinition = $jsonTemplate `
    -replace '<REPO_PROJECT_ID>', $REPO_PROJECT_ID `
    -replace '<REPO_PROJECT_NAME>', $REPO_PROJECT_NAME `
    -replace '<PIPELINE_PROJECT_ID>', $PIPELINE_PROJECT_ID `
    -replace '<PIPELINE_PROJECT_NAME>', $PIPELINE_PROJECT_NAME `
    -replace '<REPO_ID>', $REPO_ID `
    -replace '<REPO_NAME>', $REPO_NAME `
    -replace '<DEFAULT_BRANCH>', $DEFAULT_BRANCH `
    -replace '<DEVELOPMENT_BRANCHES_JSON>', $developmentBranchesJson `
    -replace '<STAGING_BRANCHES_JSON>', $stagingBranchesJson `
    -replace '<PRODUCTION_BRANCHES_JSON>', $productionBranchesJson `
    -replace '<DEVELOPMENT_DEPLOYMENT_GROUP_ID>', $DEVELOPMENT_DEPLOYMENT_GROUP_ID `
    -replace '<DEVELOPMENT_TAGS>', $developmentTagsJson `
    -replace '<DEVELOPMENT_SCRIPT>', $developmentScriptEscaped `
    -replace '<STAGING_DEPLOYMENT_GROUP_ID>', $STAGING_DEPLOYMENT_GROUP_ID `
    -replace '<STAGING_TAGS>', $stagingTagsJson `
    -replace '<STAGING_SCRIPT>', $stagingScriptEscaped `
    -replace '<PRODUCTION_DEPLOYMENT_GROUP_ID>', $PRODUCTION_DEPLOYMENT_GROUP_ID `
    -replace '<PRODUCTION_TAGS>', $productionTagsJson `
    -replace '<PRODUCTION_SCRIPT>', $productionScriptEscaped

# Save processed JSON
$jsonDefinition | Out-File -FilePath "release-definition.processed.json" -Encoding utf8
Write-Host "✓ Processed definition saved to: release-definition.processed.json" -ForegroundColor Green

Write-Host ""
Write-Host "Step 6: Importing release pipeline into $PIPELINE_PROJECT_NAME..." -ForegroundColor Blue

try {
    $importUrl = "https://vsrm.dev.azure.com/$ORGANIZATION_NAME/$PIPELINE_PROJECT_NAME/_apis/release/definitions?api-version=7.1"
    $importResponse = Invoke-RestMethod -Uri $importUrl -Method Post -Headers $headers -Body $jsonDefinition

    $RELEASE_ID = $importResponse.id

    if ([string]::IsNullOrEmpty($RELEASE_ID)) {
        throw "Failed to import release pipeline"
    }

    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "✓ Success!" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "Release Pipeline ID: $RELEASE_ID" -ForegroundColor Green
    Write-Host "Pipeline Name: Multi-Stage Auto Release" -ForegroundColor Green
    Write-Host ""
    Write-Host "Pipeline Details:" -ForegroundColor Blue
    Write-Host "  - Created in: $PIPELINE_PROJECT_NAME" -ForegroundColor Blue
    Write-Host "  - Source repo: $REPO_PROJECT_NAME/$REPO_NAME" -ForegroundColor Blue
    Write-Host ""
    Write-Host "View your pipeline at:" -ForegroundColor Blue
    Write-Host "https://dev.azure.com/$ORGANIZATION_NAME/$PIPELINE_PROJECT_NAME/_release?definitionId=$RELEASE_ID" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Tag servers in deployment groups with appropriate tags:" -ForegroundColor Yellow
    Write-Host "   - Development: $DEVELOPMENT_TAGS" -ForegroundColor Yellow
    Write-Host "   - Staging: $STAGING_TAGS" -ForegroundColor Yellow
    Write-Host "   - Production: $PRODUCTION_TAGS" -ForegroundColor Yellow
    Write-Host "2. Test the pipeline by pushing to configured branches:" -ForegroundColor Yellow
    Write-Host "   - Development: $DEVELOPMENT_BRANCHES" -ForegroundColor Yellow
    Write-Host "   - Staging: $STAGING_BRANCHES" -ForegroundColor Yellow
    Write-Host "   - Production: $PRODUCTION_BRANCHES" -ForegroundColor Yellow
    Write-Host "3. Customize deployment scripts in config file as needed" -ForegroundColor Yellow
    Write-Host ""

} catch {
    Write-Host "Error: Failed to import release pipeline" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit 1
}
