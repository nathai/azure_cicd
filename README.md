# Azure DevOps Pipelines với Terraform

Quản lý Build và Release Pipelines trong Azure DevOps bằng Terraform.

[English version / Phiên bản tiếng Anh](#azure-devops-pipelines-with-terraform)

---

## ⚠️ Quan trọng

Repository này **KHÔNG tạo** Azure DevOps Project hoặc Git Repository.

Bạn cần có sẵn:
- ✅ Azure DevOps Project đã được tạo
- ✅ Git Repository đã được tạo trong project đó
- ✅ Pipeline YAML files đã được commit vào repository

Repository này chỉ tạo:
- ✅ Build Pipeline (CI)
- ✅ Release Pipeline (CD)
- ✅ Environments (Development, Staging, Production)
- ✅ Variable Groups (biến dùng chung)

---

## Cấu trúc Files

```
.
├── provider.tf              # Cấu hình Azure DevOps provider
├── data-sources.tf          # Reference đến project và repo có sẵn
├── build-pipeline.tf        # Build Pipeline (CI)
├── release-pipeline.tf      # Release Pipeline (CD)
├── environments.tf          # Deployment environments
├── variable-groups.tf       # Variable groups
├── variables.tf             # Khai báo biến
├── outputs.tf               # Outputs
├── terraform.tfvars.example # Ví dụ cấu hình
└── README.md               # Tài liệu này
```

Mỗi pipeline được quản lý trong **file riêng biệt** để dễ dàng customize.

---

## Yêu cầu

### 1. Terraform
```bash
terraform --version  # >= 1.0
```

### 2. Azure DevOps Personal Access Token (PAT)

Tạo PAT với các quyền:
- **Build** (Read & Execute)
- **Code** (Read)
- **Environment** (Read & Manage)
- **Variable Groups** (Read, Create, & Manage)

Hướng dẫn tạo PAT:
1. Truy cập: `https://dev.azure.com/your-org/_usersSettings/tokens`
2. Click **New Token**
3. Chọn các quyền trên
4. Copy token (chỉ hiển thị một lần!)

### 3. Project và Repository có sẵn

Đảm bảo bạn đã có:
- Project trong Azure DevOps
- Repository trong project đó
- File YAML pipelines đã commit vào repo:
  - `azure-pipelines.yml` (cho build)
  - `azure-release-pipeline.yml` (cho release)

---

## Hướng dẫn Nhanh

### Bước 1: Clone và Cấu hình

```bash
# Clone repository này
git clone <your-repo>
cd azure_cicd

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Chỉnh sửa terraform.tfvars
nano terraform.tfvars
```

### Bước 2: Cấu hình terraform.tfvars

```hcl
# Azure DevOps connection
org_service_url       = "https://dev.azure.com/your-company"
personal_access_token = "your-pat-token-here"

# QUAN TRỌNG: Tên phải khớp CHÍNH XÁC với Azure DevOps
project_name    = "MyExistingProject"
repository_name = "my-existing-repo"

# Build Pipeline
build_pipeline_name      = "MyApp-CI"
build_pipeline_yaml_path = "azure-pipelines.yml"

# Release Pipeline
release_pipeline_name      = "MyApp-Release"
release_pipeline_yaml_path = "azure-release-pipeline.yml"

# Variable Group
variable_group_name = "MyApp-Variables"
pipeline_variables = {
  environment = {
    value     = "production"
    is_secret = false
  }
  api_key = {
    value     = "secret-key-123"
    is_secret = true
  }
}

# Environments
environments = [
  { name = "Development" },
  { name = "Staging" },
  { name = "Production" }
]
```

### Bước 3: Deploy

```bash
# Khởi tạo Terraform
terraform init

# Xem preview
terraform plan

# Tạo pipelines
terraform apply

# Xem kết quả
terraform output
```

### Bước 4: Truy cập Pipelines

Sau khi apply thành công, truy cập:
```bash
# Lấy URLs
terraform output build_pipeline_url
terraform output release_pipeline_url
```

Hoặc vào Azure DevOps:
- Pipelines → Pipelines → Bạn sẽ thấy 2 pipelines mới

---

## Tùy chỉnh

### Lưu Pipelines vào Project khác

**Use case:** Repository nằm ở Project A, nhưng bạn muốn pipelines được tạo ở Project B.

```hcl
# terraform.tfvars
project_name          = "SourceCodeProject"    # Project chứa repository
repository_name       = "my-app-repo"
pipeline_project_name = "DevOpsPipelinesProject"  # Project để lưu pipelines

# Pipelines sẽ được tạo trong "DevOpsPipelinesProject"
# nhưng sẽ reference code từ "SourceCodeProject/my-app-repo"
```

**Khi nào dùng:**
- Tách biệt source code và CI/CD infrastructure
- Một team quản lý code, team khác quản lý pipelines
- Tổ chức theo business units

**Lưu ý:**
- Nếu không chỉ định `pipeline_project_name`, pipelines sẽ được tạo cùng project với repository
- PAT cần có quyền truy cập **CẢ HAI** projects

### Chỉ tạo Build Pipeline

Nếu chỉ muốn tạo build pipeline, xóa/disable file `release-pipeline.tf`:

```bash
mv release-pipeline.tf release-pipeline.tf.disabled
```

### Chỉ tạo Release Pipeline

Nếu chỉ muốn tạo release pipeline, xóa/disable file `build-pipeline.tf`:

```bash
mv build-pipeline.tf build-pipeline.tf.disabled
```

### Không tạo Variable Group

Trong `terraform.tfvars`:
```hcl
create_variable_group = false
build_use_variable_groups = false
release_use_variable_groups = false
```

### Không tạo Environments

Trong `terraform.tfvars`:
```hcl
create_environments = false
```

### Thêm nhiều biến

```hcl
pipeline_variables = {
  app_name = {
    value     = "MyApplication"
    is_secret = false
  }
  version = {
    value     = "2.0.0"
    is_secret = false
  }
  db_password = {
    value     = "super-secret"
    is_secret = true
  }
  azure_subscription = {
    value     = "Production-Subscription"
    is_secret = false
  }
}
```

### Thêm/Bớt Environments

```hcl
environments = [
  { name = "Development" },
  { name = "QA" },
  { name = "UAT" },
  { name = "Staging" },
  { name = "Production" }
]
```

---

## Quản lý

### Xem trạng thái hiện tại

```bash
terraform show
```

### Cập nhật pipelines

Sau khi sửa `terraform.tfvars`:
```bash
terraform plan
terraform apply
```

### Xóa pipelines

```bash
terraform destroy
```

### Format code

```bash
terraform fmt -recursive
```

### Validate

```bash
terraform validate
```

---

## Pipeline YAML Templates

### Build Pipeline (azure-pipelines.yml)

```yaml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: MyApp-Variables  # Variable group từ Terraform

stages:
  - stage: Build
    jobs:
      - job: BuildJob
        steps:
          - script: echo "Building..."
          - script: echo "Testing..."
          - task: PublishBuildArtifacts@1
```

### Release Pipeline (azure-release-pipeline.yml)

```yaml
trigger: none

resources:
  pipelines:
    - pipeline: buildPipeline
      source: 'MyApp-CI'

variables:
  - group: MyApp-Variables

stages:
  - stage: Development
    jobs:
      - deployment: DeployDev
        environment: 'Development'
        strategy:
          runOnce:
            deploy:
              steps:
                - script: echo "Deploying to Dev"

  - stage: Production
    dependsOn: Development
    jobs:
      - deployment: DeployProd
        environment: 'Production'
        strategy:
          runOnce:
            deploy:
              steps:
                - script: echo "Deploying to Prod"
```

---

## Troubleshooting

### Lỗi: Project not found

```
Error: Project "XXX" was not found
```

**Giải pháp:**
- Kiểm tra tên project trong `terraform.tfvars` khớp chính xác
- Tên có phân biệt chữ hoa/thường
- Kiểm tra PAT có quyền truy cập project

### Lỗi: Repository not found

```
Error: Repository "XXX" was not found
```

**Giải pháp:**
- Kiểm tra tên repository khớp chính xác
- Repository phải nằm trong project đã chỉ định
- Kiểm tra PAT có quyền đọc code

### Lỗi: YAML file not found

```
Error: Could not find file azure-pipelines.yml
```

**Giải pháp:**
- Commit file YAML vào repository
- Kiểm tra đường dẫn trong `terraform.tfvars`
- Đảm bảo file đã được push lên remote

### Lỗi: Variable group already exists

```
Error: Variable group "XXX" already exists
```

**Giải pháp:**
```bash
# Import variable group hiện có
terraform import azuredevops_variable_group.pipeline_vars <project_id>/<group_id>

# Hoặc đổi tên variable group trong terraform.tfvars
```

---

## Best Practices

1. **Luôn commit YAML files trước**
   - Pipeline YAML phải có trong repository
   - Terraform chỉ tạo pipeline definition, không tạo YAML

2. **Quản lý secrets an toàn**
   - Đặt `is_secret = true` cho sensitive variables
   - Không commit `terraform.tfvars` vào git
   - Sử dụng `.gitignore` (đã có sẵn)

3. **Sử dụng Variable Groups**
   - Tập trung hóa cấu hình
   - Dễ dàng thay đổi giữa các môi trường
   - Share giữa nhiều pipelines

4. **Environments cho approvals**
   - Tạo environments cho từng môi trường triển khai
   - Thiết lập approvals trong Azure DevOps UI
   - Bảo vệ Production environment

5. **Version control**
   - Commit tất cả `.tf` files vào git
   - Review changes qua pull requests
   - Tag versions khi có thay đổi lớn

---

## Ví dụ Thực tế

### Ví dụ 1: Web Application

```hcl
# terraform.tfvars
project_name    = "WebAppProject"
repository_name = "webapp-frontend"

build_pipeline_name   = "WebApp-Build"
release_pipeline_name = "WebApp-Deploy"

pipeline_variables = {
  node_version = {
    value     = "18.x"
    is_secret = false
  }
  npm_token = {
    value     = "npm_xxxxx"
    is_secret = true
  }
}

environments = [
  { name = "Dev" },
  { name = "Staging" },
  { name = "Production" }
]
```

### Ví dụ 2: Microservices

Tạo nhiều pipelines cho từng service:

```bash
# Duplicate và customize cho từng service
cp build-pipeline.tf build-pipeline-api.tf
cp build-pipeline.tf build-pipeline-web.tf
cp release-pipeline.tf release-pipeline-api.tf
cp release-pipeline.tf release-pipeline-web.tf
```

Sửa resource names trong mỗi file để tránh conflict.

---

## Lệnh hữu ích

```bash
# Makefile commands
make help      # Hiển thị các commands
make init      # Terraform init
make plan      # Terraform plan
make apply     # Terraform apply
make destroy   # Terraform destroy
make output    # Show outputs
make fmt       # Format code
make validate  # Validate config
```

---

## Giấy phép

MIT License - Thoải mái sử dụng và chỉnh sửa

---
---

# Azure DevOps Pipelines with Terraform

Manage Build and Release Pipelines in Azure DevOps using Terraform.

## ⚠️ Important

This repository does **NOT create** Azure DevOps Project or Git Repository.

You need to have:
- ✅ Existing Azure DevOps Project
- ✅ Existing Git Repository in that project
- ✅ Pipeline YAML files committed to the repository

This repository only creates:
- ✅ Build Pipeline (CI)
- ✅ Release Pipeline (CD)
- ✅ Environments (Development, Staging, Production)
- ✅ Variable Groups (shared variables)

## Quick Start

```bash
# 1. Copy example config
cp terraform.tfvars.example terraform.tfvars

# 2. Edit with your values
nano terraform.tfvars

# 3. Deploy
terraform init
terraform plan
terraform apply
```

## Configuration

Edit `terraform.tfvars`:

```hcl
org_service_url       = "https://dev.azure.com/your-org"
personal_access_token = "your-pat-token"

# IMPORTANT: Must match exact names in Azure DevOps
project_name    = "ExistingProject"
repository_name = "existing-repo"

# Pipelines to create
build_pipeline_name   = "CI-Pipeline"
release_pipeline_name = "CD-Pipeline"

# Variable group
pipeline_variables = {
  api_key = {
    value     = "secret"
    is_secret = true
  }
}
```

## File Structure

Each pipeline is managed in a **separate file**:

- `build-pipeline.tf` - Build/CI pipeline
- `release-pipeline.tf` - Release/CD pipeline
- `environments.tf` - Deployment environments
- `variable-groups.tf` - Shared variables

Easy to customize or disable individual components!

## Customization

### Store Pipelines in Different Project

**Use case:** Repository is in Project A, but you want pipelines created in Project B.

```hcl
# terraform.tfvars
project_name          = "SourceCodeProject"      # Project with repository
repository_name       = "my-app-repo"
pipeline_project_name = "DevOpsPipelinesProject" # Project for pipelines

# Pipelines will be created in "DevOpsPipelinesProject"
# but will reference code from "SourceCodeProject/my-app-repo"
```

**When to use:**
- Separate source code and CI/CD infrastructure
- Different teams manage code vs pipelines
- Organize by business units

**Note:**
- If `pipeline_project_name` is not specified, pipelines are created in same project as repository
- PAT needs access to **BOTH** projects

### Create only Build Pipeline

```bash
mv release-pipeline.tf release-pipeline.tf.disabled
```

### Create only Release Pipeline

```bash
mv build-pipeline.tf build-pipeline.tf.disabled
```

### Don't create Variable Groups

```hcl
create_variable_group = false
```

## Outputs

```bash
terraform output build_pipeline_url
terraform output release_pipeline_url
```

## Requirements

- Terraform >= 1.0
- Azure DevOps PAT with permissions:
  - Build (Read & Execute)
  - Code (Read)
  - Environment (Read & Manage)
  - Variable Groups (Read, Create, & Manage)

## License

MIT License
