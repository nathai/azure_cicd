# Azure DevOps Release Pipeline Import Script (PowerShell)
# Requires PowerShell 5.1 or later

param(
    [string]$EnvFile = "pipelines.env",
    [switch]$Help
)

Write-Host "=====================================" -ForegroundColor Blue
Write-Host "Azure DevOps Release Pipeline Import" -ForegroundColor Blue
Write-Host "=====================================" -ForegroundColor Blue
Write-Host ""

# Show usage if help requested
if ($Help) {
    Write-Host "Usage: .\import-release-pipeline.ps1 [-EnvFile <path>] [-Help]" -ForegroundColor White
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor White
    Write-Host "  -EnvFile    Path to .env configuration file (default: pipelines.env)" -ForegroundColor White
    Write-Host "  -Help       Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\import-release-pipeline.ps1                          # Uses pipelines.env" -ForegroundColor Gray
    Write-Host "  .\import-release-pipeline.ps1 -EnvFile my-app.env    # Uses my-app.env" -ForegroundColor Gray
    Write-Host "  .\import-release-pipeline.ps1 -EnvFile configs\prod.env  # Uses configs\prod.env" -ForegroundColor Gray
    Write-Host ""
    Write-Host "First time setup:" -ForegroundColor Yellow
    Write-Host "  1. Copy template: Copy-Item pipelines.env.example pipelines.env" -ForegroundColor Gray
    Write-Host "  2. Edit your values: notepad pipelines.env" -ForegroundColor Gray
    Write-Host "  3. Run import: .\import-release-pipeline.ps1 pipelines.env" -ForegroundColor Gray
    exit 0
}

# Function to parse bash-style .env file
function Import-EnvFile {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        throw "Configuration file not found: $FilePath"
    }

    $content = Get-Content -Path $FilePath -Raw
    $lines = $content -split "`n"

    $currentVar = $null
    $currentValue = ""
    $inMultilineString = $false
    $quoteType = $null

    foreach ($line in $lines) {
        # Skip comments and empty lines when not in multiline
        if (-not $inMultilineString -and ($line -match '^\s*#' -or $line -match '^\s*$')) {
            continue
        }

        # Check if starting a new variable assignment
        if (-not $inMultilineString -and $line -match '^([A-Z_][A-Z0-9_]*)=(.*)$') {
            $varName = $matches[1]
            $varValue = $matches[2]

            # Check if value starts with a quote
            if ($varValue -match "^'") {
                # Single-quoted multiline string
                $quoteType = "'"
                $inMultilineString = $true
                $currentVar = $varName
                $currentValue = $varValue.Substring(1)  # Remove leading quote

                # Check if it ends on the same line
                if ($currentValue -match "'$") {
                    $currentValue = $currentValue.Substring(0, $currentValue.Length - 1)
                    Set-Variable -Name $varName -Value $currentValue -Scope Script
                    $inMultilineString = $false
                    $currentVar = $null
                    $currentValue = ""
                }
            }
            elseif ($varValue -match '^"') {
                # Double-quoted string
                $quoteType = '"'
                $varValue = $varValue.Substring(1)  # Remove leading quote
                if ($varValue -match '"$') {
                    $varValue = $varValue.Substring(0, $varValue.Length - 1)
                    Set-Variable -Name $varName -Value $varValue -Scope Script
                } else {
                    $inMultilineString = $true
                    $currentVar = $varName
                    $currentValue = $varValue
                }
            }
            else {
                # Unquoted value
                Set-Variable -Name $varName -Value $varValue -Scope Script
            }
        }
        elseif ($inMultilineString) {
            # Continue reading multiline string
            if ($line -match "$quoteType$") {
                # End of multiline string
                $currentValue += "`n" + $line.Substring(0, $line.Length - 1)
                Set-Variable -Name $currentVar -Value $currentValue -Scope Script
                $inMultilineString = $false
                $currentVar = $null
                $currentValue = ""
                $quoteType = $null
            } else {
                # Continue multiline
                $currentValue += "`n" + $line
            }
        }
    }
}

# Load configuration
try {
    Write-Host "Loading configuration from: $EnvFile" -ForegroundColor Green
    Import-EnvFile -FilePath $EnvFile
    Write-Host "Configuration loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "First time setup:" -ForegroundColor Yellow
    Write-Host "  1. Copy template: " -NoNewline
    Write-Host "Copy-Item pipelines.env.example pipelines.env" -ForegroundColor Cyan
    Write-Host "  2. Edit your values: " -NoNewline
    Write-Host "notepad pipelines.env" -ForegroundColor Cyan
    Write-Host "  3. Run import: " -NoNewline
    Write-Host ".\import-release-pipeline.ps1 pipelines.env" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or specify a different config file:" -ForegroundColor Yellow
    Write-Host "  .\import-release-pipeline.ps1 -EnvFile my-custom.env" -ForegroundColor Cyan
    exit 1
}
Write-Host ""

# Parse REPO_URL if provided (auto-extract organization, project, repo names)
if (-not [string]::IsNullOrEmpty($REPO_URL)) {
    Write-Host "Parsing repository URL..." -ForegroundColor Blue

    # Support both URL formats:
    # https://dev.azure.com/{org}/{project}/_git/{repo}
    # https://{org}.visualstudio.com/{project}/_git/{repo}

    if ($REPO_URL -match 'https://dev\.azure\.com/([^/]+)/([^/]+)/_git/([^/]+)') {
        $ORGANIZATION_NAME = $matches[1]
        $REPO_PROJECT_NAME = $matches[2]
        $REPO_NAME = $matches[3]
        Write-Host "✓ Extracted from URL:" -ForegroundColor Green
        Write-Host "  - Organization: $ORGANIZATION_NAME" -ForegroundColor Green
        Write-Host "  - Project: $REPO_PROJECT_NAME" -ForegroundColor Green
        Write-Host "  - Repository: $REPO_NAME" -ForegroundColor Green
    }
    elseif ($REPO_URL -match 'https://([^.]+)\.visualstudio\.com/([^/]+)/_git/([^/]+)') {
        $ORGANIZATION_NAME = $matches[1]
        $REPO_PROJECT_NAME = $matches[2]
        $REPO_NAME = $matches[3]
        Write-Host "✓ Extracted from URL:" -ForegroundColor Green
        Write-Host "  - Organization: $ORGANIZATION_NAME" -ForegroundColor Green
        Write-Host "  - Project: $REPO_PROJECT_NAME" -ForegroundColor Green
        Write-Host "  - Repository: $REPO_NAME" -ForegroundColor Green
    }
    else {
        Write-Host "Error: Invalid repository URL format" -ForegroundColor Red
        Write-Host "Expected format:" -ForegroundColor Red
        Write-Host "  https://dev.azure.com/{org}/{project}/_git/{repo}" -ForegroundColor Red
        Write-Host "  OR" -ForegroundColor Red
        Write-Host "  https://{org}.visualstudio.com/{project}/_git/{repo}" -ForegroundColor Red
        exit 1
    }
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

# Function to convert comma-separated branches to simple JSON array
function Convert-BranchesToArray {
    param([string]$branches)

    $branchArray = $branches -split ',' | ForEach-Object { $_.Trim() }
    return ($branchArray | ConvertTo-Json -Compress)
}

# Function to create branch conditions for environments
function Convert-BranchesToConditions {
    param(
        [string]$branches,
        [string]$repoName
    )

    $branchArray = $branches -split ',' | ForEach-Object { $_.Trim() }
    $conditions = ""

    foreach ($branch in $branchArray) {
        $conditions += ",{`"name`":`"_$repoName`",`"conditionType`":4,`"value`":`"{\\`"sourceBranch\\`":\\`"$branch\\`",\\`"tags\\`":[]}`",`"result`":null}"
    }

    return $conditions
}

# Combine all branches for the artifact trigger
$allBranches = "$DEVELOPMENT_BRANCHES,$STAGING_BRANCHES,$PRODUCTION_BRANCHES"
$allBranchesArray = Convert-BranchesToArray -branches $allBranches

# Create branch conditions for each environment
$developmentConditions = Convert-BranchesToConditions -branches $DEVELOPMENT_BRANCHES -repoName $REPO_NAME
$stagingConditions = Convert-BranchesToConditions -branches $STAGING_BRANCHES -repoName $REPO_NAME
$productionConditions = Convert-BranchesToConditions -branches $PRODUCTION_BRANCHES -repoName $REPO_NAME

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

# Function to convert key=value pairs to JSON object
function Convert-VariablesToJson {
    param([string]$variables)

    if ([string]::IsNullOrWhiteSpace($variables)) {
        return "{}"
    }

    $lines = $variables -split "`n" | Where-Object { $_ -match '^\s*[^#]' -and $_ -match '=' }

    if ($lines.Count -eq 0) {
        return "{}"
    }

    $varObjects = @()
    foreach ($line in $lines) {
        if ($line -match '^\s*([^=]+?)\s*=\s*(.+?)\s*$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $varObjects += "`"$key`":{`"value`":`"$value`"}"
        }
    }

    return "{" + ($varObjects -join ",") + "}"
}

# Convert variables to JSON
$pipelineVariablesJson = Convert-VariablesToJson -variables $PIPELINE_VARIABLES
$developmentVariablesJson = Convert-VariablesToJson -variables $DEVELOPMENT_VARIABLES
$stagingVariablesJson = Convert-VariablesToJson -variables $STAGING_VARIABLES
$productionVariablesJson = Convert-VariablesToJson -variables $PRODUCTION_VARIABLES

# Escape scripts for JSON (escape backslashes first, then quotes, then add newlines)
$developmentScriptEscaped = $DEVELOPMENT_SCRIPT -replace '\\','\\\\' -replace '"','\"' -replace "`r`n","\n" -replace "`n","\n" -replace '\n$',''
$stagingScriptEscaped = $STAGING_SCRIPT -replace '\\','\\\\' -replace '"','\"' -replace "`r`n","\n" -replace "`n","\n" -replace '\n$',''
$productionScriptEscaped = $PRODUCTION_SCRIPT -replace '\\','\\\\' -replace '"','\"' -replace "`r`n","\n" -replace "`n","\n" -replace '\n$',''

# Replace placeholders
$jsonDefinition = $jsonTemplate `
    -replace '<PIPELINE_NAME>', $PIPELINE_NAME `
    -replace '<REPO_PROJECT_ID>', $REPO_PROJECT_ID `
    -replace '<REPO_PROJECT_NAME>', $REPO_PROJECT_NAME `
    -replace '<PIPELINE_PROJECT_ID>', $PIPELINE_PROJECT_ID `
    -replace '<PIPELINE_PROJECT_NAME>', $PIPELINE_PROJECT_NAME `
    -replace '<REPO_ID>', $REPO_ID `
    -replace '<REPO_NAME>', $REPO_NAME `
    -replace '<DEFAULT_BRANCH>', $DEFAULT_BRANCH `
    -replace '<ALL_BRANCHES_ARRAY>', $allBranchesArray `
    -replace '<DEVELOPMENT_CONDITIONS>', $developmentConditions `
    -replace '<STAGING_CONDITIONS>', $stagingConditions `
    -replace '<PRODUCTION_CONDITIONS>', $productionConditions `
    -replace '<PIPELINE_VARIABLES>', $pipelineVariablesJson `
    -replace '<DEVELOPMENT_VARIABLES>', $developmentVariablesJson `
    -replace '<STAGING_VARIABLES>', $stagingVariablesJson `
    -replace '<PRODUCTION_VARIABLES>', $productionVariablesJson `
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
