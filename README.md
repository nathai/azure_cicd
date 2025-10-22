# Azure DevOps Release Pipeline with Terraform

This repository contains Terraform configuration to create and manage Azure DevOps release pipelines automatically.

[Vietnamese version / Phiên bản tiếng Việt](#phiên-bản-tiếng-việt)

## Two Usage Modes

This repository supports **two different usage modes**:

### 1. Full Setup Mode (Create Everything)
Create a complete Azure DevOps setup from scratch including project, repository, and pipelines.

**Use when:** Starting a new project
**What gets created:** Project + Repository + Pipelines + Environments + Variable Groups

📖 [See Quick Start below](#quick-start)

### 2. Pipelines-Only Mode (Use Existing Project/Repo)
Add pipelines to your existing Azure DevOps project and repository.

**Use when:** You already have a project and repo created manually
**What gets created:** Only Pipelines + Environments + Variable Groups

📖 [See Existing Resources Guide](README-EXISTING-RESOURCES.md)

## Features

- **Project Management**: Automatically create Azure DevOps projects (Full mode)
- **Repository Setup**: Set up Git repositories (Full mode)
- **Build Pipelines**: Configure CI pipelines
- **Release Pipelines**: Create multi-stage CD pipelines
- **Environments**: Manage deployment environments (Dev, Staging, Production)
- **Variable Groups**: Centralized variable management
- **YAML Pipelines**: Modern YAML-based pipeline configuration
- **Flexible**: Works with new or existing projects

## Prerequisites

1. **Azure DevOps Account**: You need an active Azure DevOps organization
2. **Terraform**: Install Terraform >= 1.0
3. **Personal Access Token (PAT)**: Create a PAT with the following scopes:
   - Agent Pools (Read & Manage)
   - Build (Read & Execute)
   - Code (Full)
   - Environment (Read & Manage)
   - Project and Team (Read, Write, & Manage)
   - Release (Read, Write, Execute & Manage)
   - Service Connections (Read, Query, & Manage)
   - Variable Groups (Read, Create, & Manage)

## Quick Start

### 1. Create Personal Access Token

1. Go to Azure DevOps: `https://dev.azure.com/your-organization`
2. Click on User Settings (top right) → Personal Access Tokens
3. Click "New Token"
4. Give it a name and select the required scopes (listed above)
5. Copy the token (you won't see it again!)

### 2. Configure Terraform

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

Update the following values:
```hcl
org_service_url       = "https://dev.azure.com/your-organization"
personal_access_token = "your-pat-token-here"
project_name          = "MyProject"
repository_name       = "my-application"
```

### 3. Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Access Your Pipeline

After successful deployment, Terraform will output:
- Project URL
- Repository URL
- Release Pipeline URL

## Project Structure

```
.
├── provider.tf                    # Provider configuration
├── main.tf                        # Main resources
├── variables.tf                   # Variable definitions
├── outputs.tf                     # Output definitions
├── terraform.tfvars.example       # Example configuration
├── azure-pipelines.yml            # CI pipeline template
├── azure-release-pipeline.yml     # CD pipeline template
└── README.md                      # Documentation
```

## Resources Created

1. **Azure DevOps Project**: A new project with enabled features
2. **Git Repository**: Source code repository
3. **Build Definition**: CI pipeline for building and testing
4. **Release Pipeline**: Multi-stage CD pipeline
5. **Environments**: Development, Staging, Production
6. **Variable Group**: Shared variables for pipelines

## Customization

### Adding Environments

Edit `terraform.tfvars`:

```hcl
environments = [
  {
    name      = "Development"
    order     = 1
    approvers = []
  },
  {
    name      = "QA"
    order     = 2
    approvers = ["qa-lead@example.com"]
  },
  {
    name      = "Staging"
    order     = 3
    approvers = ["dev-lead@example.com"]
  },
  {
    name      = "Production"
    order     = 4
    approvers = ["cto@example.com", "ops-lead@example.com"]
  }
]
```

### Configuring Azure Service Connection

Uncomment the service endpoint section in `main.tf` and add variables:

```hcl
# In variables.tf
variable "azure_service_principal_id" {
  description = "Azure Service Principal ID"
  type        = string
}

variable "azure_service_principal_key" {
  description = "Azure Service Principal Key"
  type        = string
  sensitive   = true
}

# ... other Azure variables
```

## Pipeline Workflow

### CI Pipeline (azure-pipelines.yml)
1. Triggered on push to main/develop branches
2. Build application
3. Run tests
4. Publish artifacts

### CD Pipeline (azure-release-pipeline.yml)
1. Triggered on successful CI build
2. Deploy to Development (automatic)
3. Deploy to Staging (requires approval)
4. Deploy to Production (requires approval)

## Management Commands

```bash
# View current state
terraform show

# Update infrastructure
terraform apply

# Destroy all resources
terraform destroy

# Format Terraform files
terraform fmt

# Validate configuration
terraform validate
```

## Best Practices

1. **Never commit `terraform.tfvars`**: Contains sensitive data
2. **Use remote state**: Store state in Azure Storage or Terraform Cloud
3. **Enable branch policies**: Protect main branch
4. **Set up approvals**: Require approvals for production deployments
5. **Use variable groups**: Centralize configuration
6. **Version control YAML**: Keep pipeline definitions in source control

## Troubleshooting

### Authentication Issues
```bash
# Verify PAT has correct permissions
# Ensure PAT has not expired
# Check org_service_url format
```

### Pipeline Not Triggering
```bash
# Ensure YAML files are committed to the repository
# Check trigger configuration in YAML
# Verify branch names match
```

## Security Notes

- Store PAT securely (use environment variables or secret management)
- Regularly rotate Personal Access Tokens
- Use managed identities where possible
- Limit PAT scope to minimum required permissions
- Enable Azure DevOps audit logging

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - feel free to use and modify

---

# Phiên bản tiếng Việt

## Azure DevOps Release Pipeline với Terraform

Repository này chứa cấu hình Terraform để tạo và quản lý release pipelines trong Azure DevOps một cách tự động.

## Hai chế độ sử dụng

Repository này hỗ trợ **hai chế độ sử dụng khác nhau**:

### 1. Chế độ Đầy đủ (Tạo mới toàn bộ)
Tạo một setup Azure DevOps hoàn chỉnh từ đầu bao gồm project, repository và pipelines.

**Sử dụng khi:** Bắt đầu project mới
**Tạo ra:** Project + Repository + Pipelines + Environments + Variable Groups

📖 [Xem Hướng dẫn nhanh bên dưới](#hướng-dẫn-nhanh)

### 2. Chế độ Chỉ Pipelines (Sử dụng Project/Repo có sẵn)
Thêm pipelines vào Azure DevOps project và repository đã có sẵn của bạn.

**Sử dụng khi:** Bạn đã có project và repo được tạo bằng tay
**Tạo ra:** Chỉ Pipelines + Environments + Variable Groups

📖 [Xem Hướng dẫn Existing Resources](README-EXISTING-RESOURCES.md)

## Tính năng

- **Quản lý Project**: Tự động tạo Azure DevOps projects (Chế độ đầy đủ)
- **Thiết lập Repository**: Cấu hình Git repositories (Chế độ đầy đủ)
- **Build Pipelines**: Cấu hình CI pipelines
- **Release Pipelines**: Tạo CD pipelines nhiều giai đoạn
- **Environments**: Quản lý môi trường triển khai (Dev, Staging, Production)
- **Variable Groups**: Quản lý biến tập trung
- **YAML Pipelines**: Cấu hình pipeline hiện đại dựa trên YAML
- **Linh hoạt**: Hoạt động với project mới hoặc có sẵn

## Yêu cầu

1. **Tài khoản Azure DevOps**: Cần có organization Azure DevOps đang hoạt động
2. **Terraform**: Cài đặt Terraform >= 1.0
3. **Personal Access Token (PAT)**: Tạo PAT với các quyền sau:
   - Agent Pools (Read & Manage)
   - Build (Read & Execute)
   - Code (Full)
   - Environment (Read & Manage)
   - Project and Team (Read, Write, & Manage)
   - Release (Read, Write, Execute & Manage)
   - Service Connections (Read, Query, & Manage)
   - Variable Groups (Read, Create, & Manage)

## Hướng dẫn nhanh

### 1. Tạo Personal Access Token

1. Truy cập Azure DevOps: `https://dev.azure.com/ten-organization-cua-ban`
2. Click vào User Settings (góc trên bên phải) → Personal Access Tokens
3. Click "New Token"
4. Đặt tên và chọn các quyền cần thiết (liệt kê ở trên)
5. Copy token (bạn sẽ không thấy lại nó nữa!)

### 2. Cấu hình Terraform

```bash
# Copy file cấu hình mẫu
cp terraform.tfvars.example terraform.tfvars

# Chỉnh sửa terraform.tfvars với giá trị của bạn
nano terraform.tfvars
```

Cập nhật các giá trị sau:
```hcl
org_service_url       = "https://dev.azure.com/ten-organization-cua-ban"
personal_access_token = "pat-token-cua-ban"
project_name          = "DuAnCuaToi"
repository_name       = "ung-dung-cua-toi"
```

### 3. Khởi tạo và Áp dụng

```bash
# Khởi tạo Terraform
terraform init

# Xem lại kế hoạch
terraform plan

# Áp dụng cấu hình
terraform apply
```

### 4. Truy cập Pipeline

Sau khi triển khai thành công, Terraform sẽ xuất ra:
- URL của Project
- URL của Repository
- URL của Release Pipeline

## Cấu trúc Project

```
.
├── provider.tf                    # Cấu hình provider
├── main.tf                        # Resources chính
├── variables.tf                   # Định nghĩa biến
├── outputs.tf                     # Định nghĩa outputs
├── terraform.tfvars.example       # Cấu hình mẫu
├── azure-pipelines.yml            # Template CI pipeline
├── azure-release-pipeline.yml     # Template CD pipeline
└── README.md                      # Tài liệu
```

## Resources được tạo

1. **Azure DevOps Project**: Project mới với các tính năng được kích hoạt
2. **Git Repository**: Repository mã nguồn
3. **Build Definition**: CI pipeline để build và test
4. **Release Pipeline**: CD pipeline nhiều giai đoạn
5. **Environments**: Development, Staging, Production
6. **Variable Group**: Biến dùng chung cho pipelines

## Tùy chỉnh

### Thêm Environments

Chỉnh sửa `terraform.tfvars`:

```hcl
environments = [
  {
    name      = "Development"
    order     = 1
    approvers = []
  },
  {
    name      = "QA"
    order     = 2
    approvers = ["qa-lead@example.com"]
  },
  {
    name      = "Staging"
    order     = 3
    approvers = ["dev-lead@example.com"]
  },
  {
    name      = "Production"
    order     = 4
    approvers = ["cto@example.com", "ops-lead@example.com"]
  }
]
```

## Quy trình Pipeline

### CI Pipeline (azure-pipelines.yml)
1. Được kích hoạt khi push lên nhánh main/develop
2. Build ứng dụng
3. Chạy tests
4. Publish artifacts

### CD Pipeline (azure-release-pipeline.yml)
1. Được kích hoạt sau khi CI build thành công
2. Deploy lên Development (tự động)
3. Deploy lên Staging (cần phê duyệt)
4. Deploy lên Production (cần phê duyệt)

## Lệnh quản lý

```bash
# Xem trạng thái hiện tại
terraform show

# Cập nhật infrastructure
terraform apply

# Xóa tất cả resources
terraform destroy

# Format Terraform files
terraform fmt

# Kiểm tra cấu hình
terraform validate
```

## Best Practices

1. **Không bao giờ commit `terraform.tfvars`**: Chứa dữ liệu nhạy cảm
2. **Sử dụng remote state**: Lưu state trong Azure Storage hoặc Terraform Cloud
3. **Kích hoạt branch policies**: Bảo vệ nhánh main
4. **Thiết lập approvals**: Yêu cầu phê duyệt cho production deployments
5. **Sử dụng variable groups**: Tập trung hóa cấu hình
6. **Version control YAML**: Giữ định nghĩa pipeline trong source control

## Ghi chú Bảo mật

- Lưu trữ PAT an toàn (sử dụng environment variables hoặc secret management)
- Thường xuyên xoay vòng Personal Access Tokens
- Sử dụng managed identities khi có thể
- Giới hạn phạm vi PAT đến quyền tối thiểu cần thiết
- Kích hoạt Azure DevOps audit logging

## Đóng góp

1. Fork repository
2. Tạo feature branch
3. Thực hiện thay đổi
4. Submit pull request

## Giấy phép

MIT License - thoải mái sử dụng và chỉnh sửa
