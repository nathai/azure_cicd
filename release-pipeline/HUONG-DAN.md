# Hướng Dẫn Sử Dụng Script Tạo Azure DevOps Release Pipeline

## 🎯 Tổng Quan

Script này giúp bạn tự động tạo Release Pipeline trong Azure DevOps từ file JSON template và file cấu hình `.env`.

### Cách Hoạt Động:
1. Bạn chuẩn bị file `.env` với thông tin cấu hình
2. Script đọc file `.env` và thay thế các giá trị vào JSON template
3. Script tự động import pipeline vào Azure DevOps

### Điểm Quan Trọng:
- ✅ **Scripts đã được nhúng sẵn** trong JSON template (file `release-definition.json`)
- ✅ **File .env CHỈ chứa cấu hình** (không có scripts)
- ✅ Nếu muốn thay đổi scripts → sửa trực tiếp trong file `release-definition.json`
- ✅ Hỗ trợ import pipeline vào organization/project khác với source repository

---

## 📋 Yêu Cầu Hệ Thống

### Linux/Mac (Bash):
- Bash shell
- `curl`
- `jq` (optional, để xem JSON đẹp hơn)

### Windows (PowerShell):
- PowerShell 5.1 trở lên
- Kiểm tra: `$PSVersionTable.PSVersion`

---

## 🚀 Các Bước Thực Hiện

### BƯỚC 1: Tạo Personal Access Token (PAT)

1. Đăng nhập vào Azure DevOps: `https://dev.azure.com/{organization}`

2. Click vào **User Settings** (góc trên phải) → **Personal access tokens**

3. Nhấn **+ New Token**

4. Cấu hình token:
   - **Name**: Đặt tên (ví dụ: "Pipeline-Import")
   - **Organization**: Chọn organization
   - **Expiration**: 30-90 ngày
   - **Scopes**: Chọn **Custom defined**:
     - ✅ **Build**: Read & execute
     - ✅ **Code**: Read
     - ✅ **Project and Team**: Read
     - ✅ **Release**: Read, write, execute & manage
     - ✅ **Deployment Groups**: Manage

5. Nhấn **Create** và **COPY token ngay** (chỉ hiện 1 lần!)

### BƯỚC 2: Tạo Deployment Groups

1. Vào project Azure DevOps → **Pipelines** → **Deployment groups**

2. Tạo deployment groups (hoặc dùng có sẵn):
   - Development Deployment Group
   - Staging Deployment Group
   - Production Deployment Group

3. **Lấy ID của deployment groups**:
   - Click vào deployment group
   - Xem URL: `.../_settings/agentqueues?poolId=XX&view=...`
   - Số `XX` chính là **Deployment Group ID**

4. **Ghi chú tags** của servers trong mỗi deployment group
   - Ví dụ: `["manager"]`, `["web-server","dev"]`

### BƯỚC 3: Tạo File Cấu Hình

#### Tạo file .env từ template:

**Linux/Mac:**
```bash
cd release-pipeline
cp pipelines.env.example my-pipeline.env
```

**Windows:**
```powershell
cd release-pipeline
Copy-Item pipelines.env.example my-pipeline.env
```

#### Chỉnh sửa file:

**Linux/Mac:**
```bash
nano my-pipeline.env
# hoặc: vim, code, gedit...
```

**Windows:**
```powershell
notepad my-pipeline.env
# hoặc: code my-pipeline.env
```

### BƯỚC 4: Điền Thông Tin Cấu Hình

File `.env` có cấu trúc như sau:

```bash
# ==========================================
# 1. AZURE DEVOPS PAT TOKEN
# ==========================================
AZURE_DEVOPS_PAT="your-pat-token-here"

# ==========================================
# 2. REPOSITORY URL
# ==========================================
# URL repository chứa source code
# Script sẽ tự động extract: organization, project, repo name
REPO_URL="https://dev.azure.com/EngineeringandAnalytics/TradingCockpit/_git/RenewableControlsPlatform"

# ==========================================
# 3. PIPELINE INFORMATION
# ==========================================
# Organization và project nơi pipeline sẽ được tạo
# Có thể khác với organization/project của repository
PIPELINE_ORGANIZATION_NAME="EngineeringandAnalytics"
PIPELINE_PROJECT_NAME="TradingCockpit"

# Đường dẫn folder chứa pipeline trong Azure DevOps
PIPELINE_PATH="docker-swarm"

# Tên pipeline
PIPELINE_NAME="DSW- Market Position API"

# ==========================================
# 4. PIPELINE TRIGGER BRANCHES
# ==========================================
# Các branches sẽ trigger tạo release (cách nhau bởi dấu phẩy)
PIPELINE_TRIGGER_BRANCHES="master,test-cicd"

# ==========================================
# 5. PIPELINE VARIABLES
# ==========================================
# Variables chung cho toàn bộ pipeline (format: key=value, mỗi dòng 1 cặp)
PIPELINE_VARIABLES="dockerfile_name=MarketPositionAPI/Dockerfile
image_name=marketpositionapi_market-position-api
repo_name=RenewableControlsPlatform
stack_name=MarketPositionAPI
stack_yaml=stack.yml
tag=latest
working_folder=_\$(repo_name)/MarketPositionAPI"

# ==========================================
# 6. DEFAULT BRANCH
# ==========================================
DEFAULT_BRANCH="master"

# ==========================================
# 7. DEVELOPMENT ENVIRONMENT
# ==========================================
DEVELOPMENT_DEPLOYMENT_GROUP_ID="270"
DEVELOPMENT_TAGS="manager"
DEVELOPMENT_BRANCHES="test-cicd"
DEVELOPMENT_VARIABLES="acr_name=gbcrswarmdne01
stack_folder=/mount/nfs-shared-storage01/stacks/RenewableControlsPlatform/MarketPositionAPI"

# ==========================================
# 8. STAGING ENVIRONMENT
# ==========================================
STAGING_DEPLOYMENT_GROUP_ID="270"
STAGING_TAGS="manager"
STAGING_BRANCHES="stage"
STAGING_VARIABLES="acr_name=gbcrswarmsne01"

# ==========================================
# 9. PRODUCTION ENVIRONMENT
# ==========================================
PRODUCTION_DEPLOYMENT_GROUP_ID="270"
PRODUCTION_TAGS="manager"
PRODUCTION_BRANCHES="master"
PRODUCTION_VARIABLES="acr_name=gbcrswarmpne01"
```

#### ⚠️ Giải Thích Các Trường Quan Trọng:

**REPO_URL:**
- URL của repository chứa source code
- Script tự động extract: `REPO_ORGANIZATION_NAME`, `REPO_PROJECT_NAME`, `REPO_NAME`
- Lấy từ: Azure DevOps → Repos → Copy URL từ thanh địa chỉ

**PIPELINE_ORGANIZATION_NAME và PIPELINE_PROJECT_NAME:**
- Organization và project nơi pipeline sẽ được TẠO
- Có thể KHÁC với organization/project của repository
- Cho phép import pipeline từ repo ở org này sang tạo pipeline ở org khác

**PIPELINE_PATH:**
- Đường dẫn folder trong Azure DevOps nơi pipeline sẽ được lưu
- Ví dụ: `"docker-swarm"` → pipeline sẽ nằm trong folder `\docker-swarm`
- Để trống `""` nếu muốn lưu ở root

**PIPELINE_TRIGGER_BRANCHES:**
- Danh sách branches (cách nhau bởi dấu phẩy) sẽ trigger TẠO RELEASE mới
- Ví dụ: `"master,test-cicd"` → push vào 2 branches này sẽ tạo release

**DEVELOPMENT_BRANCHES, STAGING_BRANCHES, PRODUCTION_BRANCHES:**
- Danh sách branches (cách nhau bởi dấu phẩy) sẽ trigger DEPLOY vào stage tương ứng
- Ví dụ: `DEVELOPMENT_BRANCHES="test-cicd"` → chỉ release từ branch `test-cicd` mới deploy vào Development

**PIPELINE_VARIABLES:**
- Variables chung cho toàn bộ pipeline
- Format: `key=value` (mỗi dòng 1 cặp)
- Dùng trong tất cả các stages

**DEVELOPMENT_VARIABLES, STAGING_VARIABLES, PRODUCTION_VARIABLES:**
- Variables riêng cho từng environment
- Format giống `PIPELINE_VARIABLES`
- Override pipeline variables nếu trùng tên

**Tags:**
- Danh sách tags (cách nhau bởi dấu phẩy, KHÔNG có khoảng trắng)
- Ví dụ: `"manager"` hoặc `"web-server,dev"`
- Server phải có ĐỦ TẤT CẢ tags này thì mới được deploy

### BƯỚC 5: Lưu File Cấu Hình

- `nano`: Nhấn `Ctrl+O` → `Ctrl+X`
- `notepad`: Nhấn `Ctrl+S`
- `vim`: Nhấn `Esc` → `:wq` → `Enter`

### BƯỚC 6: Chạy Script Import

#### Linux/Mac (Bash):

```bash
# Di chuyển vào thư mục
cd release-pipeline

# Cấp quyền thực thi (chỉ cần làm 1 lần)
chmod +x import-release-pipeline.sh

# Chạy script với file .env mặc định (pipelines.env)
./import-release-pipeline.sh

# Hoặc chỉ định file .env cụ thể
./import-release-pipeline.sh my-pipeline.env

# Xem hướng dẫn
./import-release-pipeline.sh --help
```

#### Windows (PowerShell):

```powershell
# Di chuyển vào thư mục
cd release-pipeline

# Cho phép chạy script (nếu cần)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Chạy script với file .env mặc định (pipelines.env)
.\import-release-pipeline.ps1

# Hoặc chỉ định file .env cụ thể
.\import-release-pipeline.ps1 -EnvFile my-pipeline.env

# Xem hướng dẫn
.\import-release-pipeline.ps1 -Help
```

### BƯỚC 7: Đợi Script Hoàn Thành

Script sẽ thực hiện:

1. ✅ Đọc file cấu hình
2. ✅ Parse REPO_URL → extract organization, project, repo name
3. ✅ Kết nối Azure DevOps với PAT token
4. ✅ Lấy Repository Project ID
5. ✅ Lấy Pipeline Project ID (nếu khác với repo project)
6. ✅ Lấy Repository ID
7. ✅ Kiểm tra Deployment Groups
8. ✅ Chuẩn bị release definition (thay thế placeholders)
9. ✅ Import pipeline vào Azure DevOps

**Kết quả thành công:**
```
=====================================
✓ Success!
=====================================
Release Pipeline ID: 12
Pipeline Name: DSW- Market Position API

Pipeline Details:
  - Created in: EngineeringandAnalytics/TradingCockpit
  - Source repo: EngineeringandAnalytics/TradingCockpit/RenewableControlsPlatform

View your pipeline at:
https://dev.azure.com/EngineeringandAnalytics/TradingCockpit/_release?definitionId=12
```

---

## ✅ Kiểm Tra Kết Quả

### 1. Truy cập Azure DevOps

Mở link được cung cấp hoặc:
1. Vào `https://dev.azure.com/{PIPELINE_ORGANIZATION_NAME}/{PIPELINE_PROJECT_NAME}`
2. Chọn **Pipelines** → **Releases**
3. Tìm pipeline với tên bạn đã đặt

### 2. Kiểm tra Pipeline

Click vào pipeline → **Edit** → Kiểm tra:

**Artifacts:**
- ✅ Source type: Azure Repos Git
- ✅ Repository đúng
- ✅ Default branch đúng

**Triggers:**
- ✅ Continuous deployment trigger: Enabled
- ✅ Branch filters: Các branches trong `PIPELINE_TRIGGER_BRANCHES`

**Stages:**
- ✅ Development, Staging, Production
- ✅ Owner: Thai Nguyen (thai.nguyen@gridbeyond.com) - từ JSON template
- ✅ Deployment groups và tags đúng
- ✅ Variables đúng
- ✅ Branch conditions đúng

**Tasks/Scripts:**
- ✅ Scripts được giữ nguyên từ JSON template gốc
- ✅ Tất cả tasks (Build and push image, Deploy stack, Reload Nginx...) đều như pipeline gốc

### 3. Test Pipeline

#### Test thủ công:
1. Nhấn **Create release**
2. Chọn artifacts và stages
3. **Create** → Theo dõi deployment

#### Test tự động:
1. Push code vào branch trong `PIPELINE_TRIGGER_BRANCHES` → tạo release tự động
2. Push vào branch trong `DEVELOPMENT_BRANCHES` → deploy vào Development
3. Push vào branch trong `STAGING_BRANCHES` → deploy vào Staging
4. Push vào branch trong `PRODUCTION_BRANCHES` → deploy vào Production

---

## 🔧 Tùy Chỉnh Scripts

### ⚠️ Scripts Được Lưu Ở Đâu?

Scripts **KHÔNG còn** trong file `.env` nữa. Scripts được nhúng trực tiếp trong file `release-definition.json`.

### Cách Thay Đổi Scripts:

#### Phương Án 1: Sửa file `release-definition.json` (Khuyến nghị)

File này là template JSON, chứa toàn bộ cấu trúc pipeline bao gồm scripts.

1. Mở file:
   ```bash
   # Linux/Mac
   nano release-pipeline/release-definition.json

   # Windows
   notepad release-pipeline\release-definition.json
   ```

2. Tìm phần `"workflowTasks"` trong mỗi environment

3. Sửa trường `"script"` trong `"inputs"`

4. Lưu file

5. Chạy lại import script:
   ```bash
   ./import-release-pipeline.sh my-pipeline.env
   ```

**Ví dụ script trong JSON:**
```json
{
  "inputs": {
    "script": "echo \"Server: $(hostname)\"\n\necho \"User: $(whoami)\"\n\ncd $(stack_folder)\ndocker stack deploy -c $(stack_yaml) $(stack_name)",
    "workingDirectory": "$(stack_folder)",
    "failOnStderr": "false"
  }
}
```

#### Phương Án 2: Sửa trực tiếp trong Azure DevOps

1. Vào pipeline → **Edit**
2. Click vào stage (Development, Staging, Production)
3. Click vào task muốn sửa
4. Sửa trường **Script**
5. **Save**

**Lưu ý:** Nếu chạy lại import script, thay đổi này sẽ BỊ GHI ĐÈ.

### Ví Dụ Scripts Deployment:

**Docker Swarm Deployment:**
```bash
echo "Server: $(hostname)"
echo "User: $(whoami)"

cd $(stack_folder)
echo "Working directory: $(pwd)"

# Remove old stack
docker stack rm $(stack_name)
sleep 5

# Deploy new stack
docker stack deploy -c $(stack_yaml) $(stack_name) --with-registry-auth

echo "Deployment completed!"
```

**Node.js Application:**
```bash
echo "Deploying Node.js app..."

# Stop application
pm2 stop myapp

# Backup
cp -r /var/www/app /var/www/app.backup.$(date +%Y%m%d)

# Copy new files
cp -r $(System.DefaultWorkingDirectory)/_MyApp/drop/* /var/www/app/

# Install dependencies
cd /var/www/app
npm install --production

# Start application
pm2 start app.js --name myapp

echo "Deployment completed!"
```

---

## ❌ Xử Lý Lỗi

### Lỗi 1: "Authentication failed"

**Nguyên nhân:** PAT token không hợp lệ

**Giải pháp:**
- Kiểm tra `AZURE_DEVOPS_PAT` trong file .env
- Tạo token mới với đủ quyền
- Đảm bảo token chưa hết hạn

### Lỗi 2: "Project not found"

**Nguyên nhân:** Tên project sai

**Giải pháp:**
- Kiểm tra `REPO_URL` đúng format
- Kiểm tra `PIPELINE_ORGANIZATION_NAME` và `PIPELINE_PROJECT_NAME` khớp với Azure DevOps
- Tên có phân biệt chữ hoa/thường

### Lỗi 3: "Repository not found"

**Nguyên nhân:** Repository không tồn tại hoặc không có quyền truy cập

**Giải pháp:**
- Kiểm tra `REPO_URL` chính xác
- Đảm bảo PAT token có quyền **Code: Read**
- Kiểm tra repository có tồn tại trong project

### Lỗi 4: "Deployment group not found"

**Nguyên nhân:** Deployment Group ID sai

**Giải pháp:**
1. Vào Azure DevOps → Pipelines → Deployment groups
2. Click vào deployment group
3. Xem URL: `...?poolId=XX`
4. Dùng số `XX` làm ID

### Lỗi 5: "Invalid JSON"

**Nguyên nhân:** Lỗi format khi thay thế placeholders

**Giải pháp:**
- Kiểm tra file `.env` không có ký tự đặc biệt lạ
- Kiểm tra variables không có dấu ngoặc kép hoặc dấu \ không escape đúng
- Xem file `release-definition.processed.json` để debug

### Lỗi 6: Pipeline import thành công nhưng không trigger

**Nguyên nhân:** Branch filter chưa đúng

**Giải pháp:**
1. Vào pipeline → Edit
2. Click icon lightning trên artifact
3. Kiểm tra **Continuous deployment trigger** = Enabled
4. Kiểm tra **Build branch filters** có đúng branches
5. Push code vào đúng branch name (phân biệt hoa/thường)

---

## 🔒 Lưu Ý Bảo Mật

1. **KHÔNG commit file `.env` lên Git**
   - File `*.env` đã được git-ignore tự động
   - Chỉ commit file `.env.example` (template)

2. **PAT Token:**
   - Lưu token an toàn (password manager, Azure Key Vault)
   - Đặt thời gian hết hạn phù hợp (30-90 ngày)
   - Không chia sẻ token
   - Xóa token khi không dùng

3. **Deployment Scripts:**
   - Không hardcode passwords trong scripts
   - Dùng Azure Key Vault hoặc Variable Groups cho secrets
   - Dùng Managed Identities khi có thể

---

## 📚 Tài Liệu Tham Khảo

- [Azure DevOps REST API - Release Definitions](https://learn.microsoft.com/en-us/rest/api/azure/devops/release/definitions)
- [Deployment Groups Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/release/deployment-groups)
- [Personal Access Tokens](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate)

---

## 🎉 Tổng Kết

Sau khi hoàn thành, bạn đã có:

✅ Azure DevOps Release Pipeline với 3 stages (Dev → Staging → Prod)
✅ Auto-trigger dựa trên branches
✅ Deployment groups với tag filtering
✅ Pipeline variables và environment variables
✅ Scripts được giữ nguyên từ pipeline gốc (Thai Nguyen's pipeline)
✅ Owner information được preserve (thai.nguyen@gridbeyond.com)

**Chúc bạn triển khai thành công! 🚀**
