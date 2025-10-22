# Azure DevOps Multi-Stage Auto Release Pipeline

This folder contains a complete Classic Release Pipeline definition for Azure DevOps with multi-stage deployment and auto-triggering based on branch names.

## 📋 Pipeline Overview

### **Pipeline Name:** Multi-Stage Auto Release

### **Features:**
- ✅ **Artifact Source:** Azure Repos Git
- ✅ **Auto-Trigger:** Based on branch names
- ✅ **Multi-Stage:** Development → Staging → Production
- ✅ **Deployment Groups:** Deploy to multiple servers
- ✅ **Inline Scripts:** No need for YAML files in repository
- ✅ **Branch Mapping:** Different branches trigger different stages

---

## 🎯 Branch Trigger Mapping

| Branch(es) | Triggers Stage | Auto-Deploy |
|------------|----------------|-------------|
| `dev1`, `dev2` | Development | ✅ Yes |
| `stage` | Staging | ✅ Yes (after Dev succeeds) |
| `prod` | Production | ✅ Yes (after Staging succeeds) |

---

## 📂 File Structure

```
release-pipeline/
├── release-definition.json          # Pipeline definition template
├── import-release-pipeline.sh       # Bash import script (Linux/Mac)
├── import-release-pipeline.ps1      # PowerShell import script (Windows)
├── config.sh                        # Bash configuration template
├── config.ps1                       # PowerShell configuration template
├── .gitignore                       # Ignore local config files
└── README.md                        # This file
```

---

## 🚀 Quick Start

### **Prerequisites**

1. **Azure DevOps Organization and Project**
   - Existing project in Azure DevOps
   - Existing Git repository in that project

2. **Personal Access Token (PAT)**
   - Create at: `https://dev.azure.com/{org}/_usersSettings/tokens`
   - Required scope: **Release** (Read, write, execute & manage)

3. **Deployment Groups** (Optional, but recommended)
   - Create deployment groups in Azure DevOps
   - Get deployment group IDs

---

## 📝 Step-by-Step Setup

### **Step 1: Create Configuration File**

#### For Linux/Mac (Bash):
```bash
cd release-pipeline
cp config.sh config.local.sh
nano config.local.sh
```

#### For Windows (PowerShell):
```powershell
cd release-pipeline
Copy-Item config.ps1 config.local.ps1
notepad config.local.ps1
```

### **Step 2: Update Configuration**

Edit `config.local.sh` (or `config.local.ps1`) with your values:

```bash
# Azure DevOps Organization and Project
ORGANIZATION_NAME="your-org-name"              # e.g., "contoso"
PROJECT_NAME="YourProjectName"                  # e.g., "MyWebApp"

# Personal Access Token
AZURE_DEVOPS_PAT="your-pat-token-here"         # Your PAT from step 1

# Repository
REPO_NAME="your-repo-name"                      # e.g., "webapp-backend"

# Deployment Group IDs (optional - can be configured later)
DEVELOPMENT_DEPLOYMENT_GROUP_ID="123"
STAGING_DEPLOYMENT_GROUP_ID="456"
PRODUCTION_DEPLOYMENT_GROUP_ID="789"
```

### **Step 3: Get Deployment Group IDs** (Optional)

If you don't have deployment groups yet, you can:

**Option A:** Create them manually in Azure DevOps:
1. Go to: `https://dev.azure.com/{org}/{project}/_settings/agentqueues`
2. Click "Deployment groups"
3. Create 3 deployment groups: Development, Staging, Production
4. Note their IDs (visible in URL)

**Option B:** Skip for now and configure later:
- The import will work without deployment group IDs
- You'll need to manually update the pipeline after import

### **Step 4: Run Import Script**

#### For Linux/Mac (Bash):
```bash
cd release-pipeline
chmod +x import-release-pipeline.sh
./import-release-pipeline.sh
```

#### For Windows (PowerShell):
```powershell
cd release-pipeline
.\import-release-pipeline.ps1
```

### **Step 5: Verify Import**

The script will output:
```
✓ Success!
Release Pipeline ID: 123
Pipeline Name: Multi-Stage Auto Release

View your pipeline at:
https://dev.azure.com/{org}/{project}/_release?definitionId=123
```

---

## 🔧 Pipeline Configuration

### **Stages**

The pipeline has 3 sequential stages:

#### **1. Development**
- **Job Name:** DeployToDevelopment
- **Triggers:** Commits to `dev1` or `dev2` branches
- **Deployment:** Via deployment group
- **Script:**
  ```bash
  echo "Deploying to Development Environment"
  echo "Hostname: $(hostname)"
  echo "Running deployment in Development on $(hostname)"
  ```

#### **2. Staging**
- **Job Name:** DeployToStaging
- **Triggers:** Commits to `stage` branch (after Dev succeeds)
- **Deployment:** Via deployment group
- **Condition:** Development stage must succeed
- **Script:**
  ```bash
  echo "Deploying to Staging Environment"
  echo "Running deployment in Staging on $(hostname)"
  ```

#### **3. Production**
- **Job Name:** DeployToProduction
- **Triggers:** Commits to `prod` branch (after Staging succeeds)
- **Deployment:** Via deployment group
- **Condition:** Staging stage must succeed
- **Script:**
  ```bash
  echo "Deploying to Production Environment"
  echo "Running deployment in Production on $(hostname)"
  ```

---

## 🎨 Customization

### **Modify Deployment Scripts**

Edit `release-definition.json` and update the `script` field in each stage:

```json
{
  "inputs": {
    "script": "#!/bin/bash\nYOUR_CUSTOM_SCRIPT_HERE"
  }
}
```

**Example: Deploy .NET Application**
```json
{
  "script": "#!/bin/bash\nset -e\ncd /var/www/myapp\ngit pull origin main\ndotnet publish -c Release\nsystemctl restart myapp"
}
```

**Example: Deploy Node.js Application**
```json
{
  "script": "#!/bin/bash\nset -e\ncd /app\nnpm install\npm2 restart app"
}
```

### **Add More Stages**

Copy an existing stage block in `release-definition.json` and:
1. Change `name` (e.g., "QA", "UAT")
2. Change `rank` (sequential order)
3. Update `conditions` (which stage must succeed first)
4. Add trigger mapping in `triggers` array

### **Change Branch Mappings**

Edit the `triggers` section in `release-definition.json`:

```json
{
  "triggerConditions": [
    {
      "sourceBranch": "your-branch-name",
      "tags": [],
      "useBuildDefinitionBranch": false
    }
  ]
}
```

---

## 📊 How It Works

### **Workflow Diagram**

```
Push to dev1/dev2 → Trigger Development Stage → Deploy to Dev servers
                                                   ↓
                                    (if succeeded) ↓
                                                   ↓
Push to stage     → Trigger Staging Stage ────→ Deploy to Staging servers
                                                   ↓
                                    (if succeeded) ↓
                                                   ↓
Push to prod      → Trigger Production Stage ──→ Deploy to Production servers
```

### **Import Process**

```
1. Load config.local.sh/ps1
   ↓
2. Fetch Project ID from Azure DevOps API
   ↓
3. Fetch Repository ID from Azure DevOps API
   ↓
4. Replace placeholders in JSON template
   ↓
5. POST to Azure DevOps Release Definition API
   ↓
6. Pipeline created! ✓
```

---

## 🔍 Troubleshooting

### **Error: Could not fetch Project ID**
- Verify `ORGANIZATION_NAME` and `PROJECT_NAME` are correct
- Check PAT has correct permissions
- Ensure project exists

### **Error: Could not fetch Repository ID**
- Verify `REPO_NAME` matches exactly (case-sensitive)
- Check repository exists in the project
- Ensure PAT has Code (Read) permission

### **Error: Failed to import release pipeline**
- Check PAT has Release (Read, write, execute & manage) permission
- Verify JSON syntax is valid
- Check deployment group IDs are valid (if configured)

### **Warning: Deployment Group IDs not configured**
- You can continue without them
- Update pipeline manually after import
- Or re-run script after creating deployment groups

### **Pipeline doesn't trigger automatically**
- Verify branch names match exactly (e.g., `dev1` not `Dev1`)
- Check trigger configuration in Azure DevOps UI
- Ensure continuous deployment is enabled

---

## 📚 Additional Resources

### **Azure DevOps REST API Documentation**
- [Release Definitions](https://learn.microsoft.com/en-us/rest/api/azure/devops/release/definitions)
- [Create Release Definition](https://learn.microsoft.com/en-us/rest/api/azure/devops/release/definitions/create)

### **Deployment Groups**
- [About Deployment Groups](https://learn.microsoft.com/en-us/azure/devops/pipelines/release/deployment-groups/)
- [Create Deployment Group](https://learn.microsoft.com/en-us/azure/devops/pipelines/release/deployment-groups/howto-provision-deployment-group-agents)

### **Task IDs**
- PowerShell Task: `d9bafed4-0b18-4f58-968d-86655b4d2ce9`
- Bash Task: `6c731c3c-3c68-459a-a5c9-bde6e6595b5b`

---

## 🔒 Security Best Practices

1. **Never commit PAT tokens**
   - Use `config.local.sh` or `config.local.ps1` (git-ignored)
   - Rotate PATs regularly

2. **Use least-privilege PATs**
   - Only grant required scopes
   - Set expiration dates

3. **Protect sensitive branches**
   - Add branch policies to `prod` and `stage`
   - Require approvals for production deployments

4. **Secure deployment scripts**
   - Don't hardcode credentials in scripts
   - Use Azure Key Vault or variable groups for secrets

---

## 🎯 Next Steps

After importing the pipeline:

1. **Configure Deployment Groups**
   - Install agents on target servers
   - Tag agents appropriately (e.g., "web-server", "api-server")

2. **Test the Pipeline**
   - Push a commit to `dev1` or `dev2` branch
   - Watch the Development stage trigger automatically
   - Verify deployment on target servers

3. **Add Approvals** (Optional)
   - Add pre-deployment approvals for Staging/Production
   - Configure notification emails

4. **Customize Scripts**
   - Update deployment scripts with actual deployment logic
   - Add health checks, rollback procedures

5. **Monitor and Iterate**
   - Monitor pipeline runs
   - Adjust timeouts, conditions as needed
   - Add additional stages if required

---

## 📞 Support

For issues or questions:
- Check Azure DevOps [Community](https://developercommunity.visualstudio.com/spaces/21/index.html)
- Review [Azure Pipelines Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/)

---

## 📄 License

MIT License - Free to use and modify
