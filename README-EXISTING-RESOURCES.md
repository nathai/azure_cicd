# Sử dụng Terraform với Project và Repository có sẵn

Hướng dẫn này dành cho trường hợp bạn đã có sẵn Azure DevOps Project và Git Repository được tạo bằng tay, và chỉ muốn sử dụng Terraform để tạo **Pipelines** (Build và Release).

[English version](#using-terraform-with-existing-project-and-repository)

## Tình huống sử dụng

Sử dụng cấu hình này khi:
- ✅ Bạn đã có Azure DevOps Project
- ✅ Bạn đã có Git Repository trong project đó
- ✅ Bạn chỉ muốn tạo CI/CD Pipelines
- ✅ Bạn chỉ muốn tạo Environments
- ✅ Bạn chỉ muốn tạo Variable Groups

## Cấu trúc Files

Để sử dụng với existing resources, bạn cần các files sau:

```
.
├── provider.tf                              # Provider (giống như bình thường)
├── main-existing-resources.tf               # Main file cho existing resources
├── outputs-existing-resources.tf            # Outputs cho existing resources
├── variables.tf                             # Variables (đã được update)
├── terraform-existing-resources.tfvars.example  # Example config
└── terraform.tfvars                         # Your actual config
```

## Hướng dẫn từng bước

### Bước 1: Chuẩn bị Project và Repository

Đảm bảo bạn đã có:

1. **Azure DevOps Project** đã được tạo
   - Truy cập: `https://dev.azure.com/your-org/_projects`
   - Ghi nhớ tên project chính xác (case-sensitive)

2. **Git Repository** trong project
   - Truy cập project → Repos
   - Ghi nhớ tên repository chính xác

3. **Pipeline YAML files** đã được commit vào repository
   - `azure-pipelines.yml` (cho CI)
   - `azure-release-pipeline.yml` (cho CD)
   - Hoặc bạn có thể tự đặt tên khác và config trong tfvars

### Bước 2: Setup Terraform Files

```bash
# 1. Đổi tên hoặc xóa main.tf cũ
mv main.tf main-new-resources.tf.backup
mv outputs.tf outputs-new-resources.tf.backup

# 2. Sử dụng files cho existing resources
mv main-existing-resources.tf main.tf
mv outputs-existing-resources.tf outputs.tf

# 3. Tạo terraform.tfvars từ example
cp terraform-existing-resources.tfvars.example terraform.tfvars

# 4. Chỉnh sửa terraform.tfvars
nano terraform.tfvars
```

### Bước 3: Cấu hình terraform.tfvars

Sửa file `terraform.tfvars` với thông tin thực tế của bạn:

```hcl
# Azure DevOps Organization
org_service_url       = "https://dev.azure.com/my-company"
personal_access_token = "your-pat-token-here"

# QUAN TRỌNG: Tên project và repo phải khớp chính xác với tên trên Azure DevOps
project_name    = "MyExistingProject"  # Tên project đã có
repository_name = "my-existing-repo"    # Tên repo đã có

# Tên pipelines (sẽ được tạo mới)
build_pipeline_name   = "MyApp-CI"
release_pipeline_name = "MyApp-CD"

# Branch mặc định
default_branch = "refs/heads/main"  # hoặc "refs/heads/master"

# Đường dẫn đến YAML files trong repo
build_pipeline_path   = "azure-pipelines.yml"
release_pipeline_path = "azure-release-pipeline.yml"

# Variable Group (sẽ được tạo)
variable_group_name = "MyApp-Variables"

# Biến trong Variable Group
pipeline_variables = {
  environment = {
    value     = "production"
    is_secret = false
  }
  api_key = {
    value     = "your-secret-key"
    is_secret = true  # Biến secret sẽ được mã hóa
  }
}

# Environments (sẽ được tạo)
environments = [
  {
    name      = "Development"
    order     = 1
    approvers = []
  },
  {
    name      = "Production"
    order     = 2
    approvers = ["manager@company.com"]
  }
]
```

### Bước 4: Khởi tạo và Apply

```bash
# Khởi tạo Terraform
terraform init

# Xem preview những gì sẽ được tạo
terraform plan

# Apply (tạo resources)
terraform apply
```

### Bước 5: Kiểm tra kết quả

Sau khi apply thành công:

```bash
# Xem outputs
terraform output

# Bạn sẽ thấy URLs để truy cập pipelines
```

Truy cập Azure DevOps để kiểm tra:
- **Pipelines** → Bạn sẽ thấy 2 pipelines mới được tạo
- **Environments** → Environments mới được tạo
- **Pipelines** → Library → Variable Groups → Variable Group mới

## Điều chỉnh theo nhu cầu

### Chỉ tạo Build Pipeline (CI)

Nếu bạn chỉ muốn tạo CI pipeline, comment out release pipeline trong `main.tf`:

```hcl
# Comment out phần này trong main.tf
# resource "azuredevops_build_definition" "release_pipeline" {
#   ...
# }
```

### Chỉ tạo Release Pipeline (CD)

Nếu bạn chỉ muốn tạo CD pipeline, comment out build pipeline trong `main.tf`:

```hcl
# Comment out phần này trong main.tf
# resource "azuredevops_build_definition" "build" {
#   ...
# }
```

### Thêm Azure Service Connection

Nếu bạn cần deploy lên Azure, cấu hình service connection:

```hcl
# Trong terraform.tfvars
create_service_connection = true
service_connection_name   = "Azure-Production"

# Cần thêm các thông tin sau:
azure_service_principal_id  = "your-sp-app-id"
azure_service_principal_key = "your-sp-password"
azure_tenant_id            = "your-tenant-id"
azure_subscription_id      = "your-subscription-id"
azure_subscription_name    = "Your Subscription Name"
```

### Sử dụng Custom Agent Pool

```hcl
# Thêm vào terraform.tfvars
agent_pool_name = "My-Self-Hosted-Pool"
```

Sau đó uncomment phần agent pool trong `main.tf`.

## Quản lý Variables

### Thêm biến thông thường

```hcl
pipeline_variables = {
  app_version = {
    value     = "1.0.0"
    is_secret = false
  }
  deploy_region = {
    value     = "eastus"
    is_secret = false
  }
}
```

### Thêm secret variables

```hcl
pipeline_variables = {
  database_password = {
    value     = "super-secret-password"
    is_secret = true
  }
  api_token = {
    value     = "secret-token-123"
    is_secret = true
  }
}
```

## Troubleshooting

### Lỗi: Project not found

```
Error: Project not found
```

**Giải pháp:**
- Kiểm tra tên project trong `terraform.tfvars` khớp chính xác với tên trên Azure DevOps
- Tên project có phân biệt chữ hoa/thường (case-sensitive)
- Kiểm tra PAT có quyền truy cập project

### Lỗi: Repository not found

```
Error: Repository not found
```

**Giải pháp:**
- Kiểm tra tên repository trong `terraform.tfvars` khớp với tên thực tế
- Repository phải nằm trong project đã chỉ định
- Kiểm tra PAT có quyền truy cập repository

### Lỗi: YAML file not found

```
Error: Pipeline YAML file not found
```

**Giải pháp:**
- Commit các file YAML (`azure-pipelines.yml`, `azure-release-pipeline.yml`) vào repository
- Kiểm tra đường dẫn file trong `terraform.tfvars` khớp với vị trí thực tế
- Đảm bảo file đã được push lên remote repository

### Lỗi: Permission denied

```
Error: Permission denied
```

**Giải pháp:**
- Kiểm tra PAT có đủ quyền:
  - Build (Read & Execute)
  - Code (Read)
  - Environment (Read & Manage)
  - Release (Read, Write, Execute & Manage)
  - Variable Groups (Read, Create, & Manage)

## Best Practices

1. **Commit YAML files trước**
   - Luôn commit và push pipeline YAML files trước khi chạy Terraform
   - Terraform cần reference đến file YAML trong repository

2. **Sử dụng Variable Groups**
   - Đặt tất cả config chung vào Variable Groups
   - Secrets nên được đánh dấu `is_secret = true`

3. **Environment Approvals**
   - Thiết lập approvers cho Production environment
   - Test workflow approval trước khi production deploy

4. **Backup cấu hình**
   - Commit terraform.tfvars vào Git (private repo)
   - Hoặc sử dụng environment variables cho PAT

5. **Version control**
   - Giữ pipeline YAML trong source control
   - Review changes qua pull requests

## So sánh với tạo mới Project

| Feature | Tạo mới Project & Repo | Sử dụng existing |
|---------|------------------------|------------------|
| Project creation | ✅ Tự động tạo | ❌ Sử dụng có sẵn |
| Repository creation | ✅ Tự động tạo | ❌ Sử dụng có sẵn |
| Build Pipeline | ✅ Tạo | ✅ Tạo |
| Release Pipeline | ✅ Tạo | ✅ Tạo |
| Environments | ✅ Tạo | ✅ Tạo |
| Variable Groups | ✅ Tạo | ✅ Tạo |
| Service Connections | ✅ Tạo | ✅ Tạo |
| Use case | Project mới từ đầu | Thêm automation vào project có sẵn |

## Ví dụ đầy đủ

Xem file `terraform-existing-resources.tfvars.example` để có ví dụ cấu hình hoàn chỉnh.

## Câu hỏi thường gặp

**Q: Tôi có thể import existing pipelines không?**
A: Có, sử dụng `terraform import`:
```bash
terraform import azuredevops_build_definition.build <project_id>/<pipeline_id>
```

**Q: Tôi có thể quản lý cả project cũ và mới?**
A: Có, tạo 2 workspace Terraform riêng biệt hoặc sử dụng modules.

**Q: Variable Groups có sync với Azure DevOps không?**
A: Có, Terraform sẽ sync variables. Nhưng nếu bạn thay đổi trực tiếp trên Azure DevOps, chạy `terraform plan` để xem diff.

---

# Using Terraform with Existing Project and Repository

This guide is for when you already have an Azure DevOps Project and Git Repository created manually, and only want to use Terraform to create **Pipelines** (Build and Release).

## Use Cases

Use this configuration when:
- ✅ You already have an Azure DevOps Project
- ✅ You already have a Git Repository in that project
- ✅ You only want to create CI/CD Pipelines
- ✅ You only want to create Environments
- ✅ You only want to create Variable Groups

## Quick Start

### Step 1: Prepare Files

```bash
# Rename or backup the full setup files
mv main.tf main-new-resources.tf.backup
mv outputs.tf outputs-new-resources.tf.backup

# Use existing resources files
mv main-existing-resources.tf main.tf
mv outputs-existing-resources.tf outputs.tf

# Create config from example
cp terraform-existing-resources.tfvars.example terraform.tfvars
```

### Step 2: Configure terraform.tfvars

Edit `terraform.tfvars` with your actual values:

```hcl
org_service_url       = "https://dev.azure.com/your-org"
personal_access_token = "your-pat-here"

# IMPORTANT: Must match exact names in Azure DevOps
project_name    = "ExistingProject"
repository_name = "existing-repo"

build_pipeline_name   = "CI-Pipeline"
release_pipeline_name = "CD-Pipeline"
```

### Step 3: Apply

```bash
terraform init
terraform plan
terraform apply
```

## What Gets Created

When using existing project/repo, Terraform creates:

1. ✅ **Build Pipeline** (CI)
2. ✅ **Release Pipeline** (CD)
3. ✅ **Environments** (Dev, Staging, Production)
4. ✅ **Variable Groups** (shared variables)
5. ✅ **Service Connections** (optional)

What is **NOT** created:
- ❌ Project (uses existing)
- ❌ Repository (uses existing)

## For More Details

See the Vietnamese section above for:
- Detailed configuration examples
- Troubleshooting guide
- Best practices
- Advanced customization options

## Example Files

- `terraform-existing-resources.tfvars.example` - Complete configuration example
- `main-existing-resources.tf` - Main Terraform configuration
- `outputs-existing-resources.tf` - Output definitions
