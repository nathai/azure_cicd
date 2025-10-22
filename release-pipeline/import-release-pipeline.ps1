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

# Validate required variables
if ([string]::IsNullOrEmpty($ORGANIZATION_NAME) -or
    [string]::IsNullOrEmpty($PROJECT_NAME) -or
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
Write-Host "Step 1: Fetching Project ID..." -ForegroundColor Blue

try {
    $projectUrl = "https://dev.azure.com/$ORGANIZATION_NAME/_apis/projects/$PROJECT_NAME`?api-version=7.1"
    $projectResponse = Invoke-RestMethod -Uri $projectUrl -Method Get -Headers $headers
    $PROJECT_ID = $projectResponse.id

    if ([string]::IsNullOrEmpty($PROJECT_ID)) {
        throw "Could not fetch Project ID"
    }

    Write-Host "✓ Project ID: $PROJECT_ID" -ForegroundColor Green
} catch {
    Write-Host "Error: Could not fetch Project ID" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Fetching Repository ID..." -ForegroundColor Blue

try {
    $repoUrl = "https://dev.azure.com/$ORGANIZATION_NAME/$PROJECT_NAME/_apis/git/repositories/$REPO_NAME`?api-version=7.1"
    $repoResponse = Invoke-RestMethod -Uri $repoUrl -Method Get -Headers $headers
    $REPO_ID = $repoResponse.id

    if ([string]::IsNullOrEmpty($REPO_ID)) {
        throw "Could not fetch Repository ID"
    }

    Write-Host "✓ Repository ID: $REPO_ID" -ForegroundColor Green
} catch {
    Write-Host "Error: Could not fetch Repository ID" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 3: Validating Deployment Groups..." -ForegroundColor Blue

if ([string]::IsNullOrEmpty($DEVELOPMENT_DEPLOYMENT_GROUP_ID) -or
    [string]::IsNullOrEmpty($STAGING_DEPLOYMENT_GROUP_ID) -or
    [string]::IsNullOrEmpty($PRODUCTION_DEPLOYMENT_GROUP_ID)) {
    Write-Host "Warning: Deployment Group IDs not configured" -ForegroundColor Yellow
    Write-Host "Please update config.local.ps1 with deployment group IDs" -ForegroundColor Yellow
    Write-Host "You can find them at:" -ForegroundColor Yellow
    Write-Host "https://dev.azure.com/$ORGANIZATION_NAME/$PROJECT_NAME/_settings/agentqueues" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        exit 1
    }
} else {
    Write-Host "✓ Development Deployment Group ID: $DEVELOPMENT_DEPLOYMENT_GROUP_ID" -ForegroundColor Green
    Write-Host "✓ Staging Deployment Group ID: $STAGING_DEPLOYMENT_GROUP_ID" -ForegroundColor Green
    Write-Host "✓ Production Deployment Group ID: $PRODUCTION_DEPLOYMENT_GROUP_ID" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 4: Preparing release definition..." -ForegroundColor Blue

# Read JSON template
$jsonTemplate = Get-Content -Path "release-definition.json" -Raw

# Replace placeholders
$jsonDefinition = $jsonTemplate `
    -replace '<PROJECT_ID>', $PROJECT_ID `
    -replace '<PROJECT_NAME>', $PROJECT_NAME `
    -replace '<REPO_ID>', $REPO_ID `
    -replace '<REPO_NAME>', $REPO_NAME `
    -replace '<DEVELOPMENT_DEPLOYMENT_GROUP_ID>', $DEVELOPMENT_DEPLOYMENT_GROUP_ID `
    -replace '<STAGING_DEPLOYMENT_GROUP_ID>', $STAGING_DEPLOYMENT_GROUP_ID `
    -replace '<PRODUCTION_DEPLOYMENT_GROUP_ID>', $PRODUCTION_DEPLOYMENT_GROUP_ID

# Save processed JSON
$jsonDefinition | Out-File -FilePath "release-definition.processed.json" -Encoding utf8
Write-Host "✓ Processed definition saved to: release-definition.processed.json" -ForegroundColor Green

Write-Host ""
Write-Host "Step 5: Importing release pipeline..." -ForegroundColor Blue

try {
    $importUrl = "https://vsrm.dev.azure.com/$ORGANIZATION_NAME/$PROJECT_NAME/_apis/release/definitions?api-version=7.1"
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
    Write-Host "View your pipeline at:" -ForegroundColor Blue
    Write-Host "https://dev.azure.com/$ORGANIZATION_NAME/$PROJECT_NAME/_release?definitionId=$RELEASE_ID" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Configure deployment group IDs if not done" -ForegroundColor Yellow
    Write-Host "2. Set up deployment group agents on target servers" -ForegroundColor Yellow
    Write-Host "3. Test the pipeline by pushing to dev1 or dev2 branches" -ForegroundColor Yellow
    Write-Host ""

} catch {
    Write-Host "Error: Failed to import release pipeline" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit 1
}
