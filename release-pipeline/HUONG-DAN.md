# Hướng Dẫn Tạo Azure DevOps Release Pipeline

## Mục Lục
1. [Yêu Cầu Hệ Thống](#yêu-cầu-hệ-thống)
2. [Chuẩn Bị](#chuẩn-bị)
3. [Các Bước Thực Hiện](#các-bước-thực-hiện)
4. [Kiểm Tra Kết Quả](#kiểm-tra-kết-quả)
5. [Xử Lý Lỗi](#xử-lý-lỗi)

---

## Yêu Cầu Hệ Thống

### Đối với Linux/Mac (sử dụng Bash):
- Bash shell
- `curl` (kiểm tra: `curl --version`)
- `jq` (không bắt buộc, nhưng nên có để xem JSON đẹp hơn)

### Đối với Windows (sử dụng PowerShell):
- PowerShell 5.1 trở lên
- Kiểm tra phiên bản: `$PSVersionTable.PSVersion`

---

## Chuẩn Bị

### Bước 1: Tạo Personal Access Token (PAT) trong Azure DevOps

1. Đăng nhập vào Azure DevOps: `https://dev.azure.com/{tên-tổ-chức-của-bạn}`

2. Nhấp vào biểu tượng User Settings (góc trên bên phải) → **Personal access tokens**

3. Nhấn nút **+ New Token**

4. Cấu hình token:
   - **Name**: Đặt tên (ví dụ: "Release-Pipeline-Import")
   - **Organization**: Chọn organization của bạn
   - **Expiration**: Chọn thời gian hết hạn (khuyến nghị: 30-90 ngày)
   - **Scopes**: Chọn **Custom defined**, sau đó chọn:
     - ✅ **Build**: Read & execute
     - ✅ **Code**: Read (nếu cần)
     - ✅ **Project and Team**: Read
     - ✅ **Release**: Read, write, execute & manage
     - ✅ **Service Connections**: Read, query, & manage
     - ✅ **Deployment Groups**: Manage

5. Nhấn **Create** và **COPY** token ngay (token chỉ hiển thị một lần!)

6. Lưu token vào nơi an toàn

### Bước 2: Tạo Deployment Groups

Bạn cần tạo 3 deployment groups trong Azure DevOps:

1. Vào project Azure DevOps của bạn

2. Điều hướng: **Pipelines** → **Deployment groups**

3. Tạo 3 deployment groups:
   - **Development-Servers** (hoặc tên bạn muốn)
   - **Staging-Servers**
   - **Production-Servers**

4. Cài đặt agent trên các server mục tiêu:
   - Nhấp vào deployment group vừa tạo
   - Chọn **Register machine**
   - Thêm **tags** cho mỗi server (ví dụ: `web-server`, `dev`, `staging`, `production`)
   - Copy và chạy script cài đặt agent trên mỗi server

5. **GHI CHÚ ID** của từng deployment group:
   - Vào từng deployment group
   - Xem URL trong trình duyệt: `.../_settings/agentpools?poolId=XX&view=...`
   - Số `XX` chính là ID cần dùng

### Bước 3: Xác Định Thông Tin Repository

Bạn cần biết:
- **Tên Organization** (từ URL: `https://dev.azure.com/{TÊN-NÀY}`)
- **Tên Project chứa Repository** (project có source code)
- **Tên Repository**
- **Tên Project chứa Pipeline** (có thể giống hoặc khác project chứa repo)

---

## Các Bước Thực Hiện

### BƯỚC 1: Copy File Cấu Hình

#### Với Linux/Mac:
```bash
cd release-pipeline
cp config.sh config.local.sh
```

#### Với Windows PowerShell:
```powershell
cd release-pipeline
Copy-Item config.ps1 config.local.ps1
```

### BƯỚC 2: Chỉnh Sửa File Cấu Hình

#### Với Linux/Mac - Mở file `config.local.sh`:
```bash
nano config.local.sh
# Hoặc dùng editor bạn thích: vim, code, gedit...
```

#### Với Windows - Mở file `config.local.ps1`:
```powershell
notepad config.local.ps1
# Hoặc dùng: code config.local.ps1
```

### BƯỚC 3: Điền Thông Tin Cấu Hình

Điền các thông tin sau vào file config:

```bash
# ==========================================
# PHẦN 1: Thông Tin Azure DevOps
# ==========================================

# Tên organization (từ URL: https://dev.azure.com/TEN-NAY)
ORGANIZATION_NAME="ten-organization-cua-ban"

# Personal Access Token (đã tạo ở bước chuẩn bị)
PAT_TOKEN="token-cua-ban-o-day"

# ==========================================
# PHẦN 2: Thông Tin Repository và Pipeline
# ==========================================

# Tên project chứa repository (source code)
REPO_PROJECT_NAME="ProjectChuaSourceCode"

# Tên repository
REPO_NAME="ten-repository"

# Branch mặc định
DEFAULT_BRANCH="main"  # hoặc "master"

# Tên project chứa pipeline (nơi lưu release pipeline)
# Để trống nếu muốn dùng cùng project với repository
PIPELINE_PROJECT_NAME=""
# Hoặc điền nếu muốn lưu ở project khác:
# PIPELINE_PROJECT_NAME="ProjectChuaPipeline"

# ==========================================
# PHẦN 3: Deployment Groups
# ==========================================

# Development Environment
DEVELOPMENT_DEPLOYMENT_GROUP_ID="1"  # Thay bằng ID thực tế
DEVELOPMENT_TAGS="web-server,dev"    # Tags để filter server

# Staging Environment
STAGING_DEPLOYMENT_GROUP_ID="2"      # Thay bằng ID thực tế
STAGING_TAGS="web-server,staging"    # Tags để filter server

# Production Environment
PRODUCTION_DEPLOYMENT_GROUP_ID="3"   # Thay bằng ID thực tế
PRODUCTION_TAGS="web-server,production"  # Tags để filter server
```

#### Ví Dụ Cấu Hình Thực Tế:

```bash
ORGANIZATION_NAME="contoso"
PAT_TOKEN="abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx"
REPO_PROJECT_NAME="MyWebApp"
REPO_NAME="webapp-repo"
DEFAULT_BRANCH="main"
PIPELINE_PROJECT_NAME="DevOps-Pipelines"  # Pipeline lưu ở project khác

DEVELOPMENT_DEPLOYMENT_GROUP_ID="12"
DEVELOPMENT_TAGS="web-server,dev,frontend"

STAGING_DEPLOYMENT_GROUP_ID="15"
STAGING_TAGS="web-server,staging,frontend"

PRODUCTION_DEPLOYMENT_GROUP_ID="18"
PRODUCTION_TAGS="web-server,production,frontend"
```

**LƯU Ý về Tags:**
- Các tags cách nhau bởi dấu phẩy (không có khoảng trắng)
- Tags phải khớp với tags đã gán cho servers trong deployment group
- Pipeline chỉ chạy trên servers có **TẤT CẢ** các tags được chỉ định

### BƯỚC 4: Lưu File Cấu Hình

- Trong `nano`: Nhấn `Ctrl+O` để lưu, `Ctrl+X` để thoát
- Trong `notepad`: Nhấn `Ctrl+S` để lưu
- Trong `vim`: Nhấn `Esc`, gõ `:wq`, nhấn `Enter`

### BƯỚC 5: Chạy Script Import

#### Với Linux/Mac:
```bash
# Cấp quyền thực thi cho script
chmod +x import-release-pipeline.sh

# Chạy script
./import-release-pipeline.sh
```

#### Với Windows PowerShell:
```powershell
# Có thể cần cho phép chạy script (chỉ cần làm 1 lần)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Chạy script
.\import-release-pipeline.ps1
```

### BƯỚC 6: Đợi Script Hoàn Thành

Script sẽ thực hiện các bước sau:

1. ✅ Kiểm tra file cấu hình
2. ✅ Kết nối Azure DevOps
3. ✅ Lấy Project ID (cả repo project và pipeline project nếu khác nhau)
4. ✅ Lấy Repository ID
5. ✅ Tạo JSON definition
6. ✅ Import pipeline vào Azure DevOps

**Kết quả thành công:**
```
========================================
✅ Import thành công!
========================================
Pipeline Name: Multi-Stage Auto Release
Pipeline ID: 42
Pipeline URL: https://dev.azure.com/{org}/{project}/_release?definitionId=42
```

---

## Kiểm Tra Kết Quả

### Bước 1: Truy Cập Azure DevOps

1. Mở trình duyệt và truy cập:
   ```
   https://dev.azure.com/{organization-name}/{pipeline-project-name}
   ```

2. Vào **Pipelines** → **Releases**

3. Bạn sẽ thấy pipeline mới: **Multi-Stage Auto Release**

### Bước 2: Kiểm Tra Cấu Hình Pipeline

1. Nhấp vào pipeline name → **Edit**

2. Kiểm tra các phần:

   **Artifacts:**
   - ✅ Source type: Azure Repos Git
   - ✅ Project: {repo-project-name}
   - ✅ Repository: {repo-name}
   - ✅ Default branch: {branch-name}

   **Continuous Deployment Trigger:**
   - ✅ Enabled
   - ✅ Build branch filters:
     - `dev1`, `dev2` → Development stage
     - `stage` → Staging stage
     - `prod` → Production stage

   **Stages:**
   - ✅ Development → Staging → Production
   - ✅ Mỗi stage có deployment group đúng
   - ✅ Tags được cấu hình đúng

### Bước 3: Test Pipeline

#### Test thủ công:
1. Nhấn **Create release**
2. Chọn artifact version
3. Chọn stages muốn deploy
4. Nhấn **Create**
5. Theo dõi quá trình deployment

#### Test tự động (auto-trigger):
1. Commit code vào branch `dev1` hoặc `dev2`
2. Pipeline tự động trigger stage Development
3. Commit vào branch `stage` → trigger Staging
4. Commit vào branch `prod` → trigger Production

---

## Xử Lý Lỗi

### Lỗi 1: "Authentication failed"

**Nguyên nhân:** PAT token không hợp lệ hoặc hết hạn

**Giải pháp:**
1. Kiểm tra PAT token trong file config
2. Tạo token mới nếu cần
3. Đảm bảo token có đủ quyền (Release: Read, write, execute & manage)

### Lỗi 2: "Project not found"

**Nguyên nhân:** Tên project hoặc repository không đúng

**Giải pháp:**
1. Kiểm tra lại `REPO_PROJECT_NAME` và `PIPELINE_PROJECT_NAME`
2. Tên phải khớp CHÍNH XÁC với tên trong Azure DevOps (có phân biệt chữ hoa/thường)
3. Vào Azure DevOps, copy chính xác tên project

### Lỗi 3: "Repository not found"

**Nguyên nhân:** Tên repository không đúng

**Giải pháp:**
1. Vào Azure DevOps → Repos
2. Copy chính xác tên repository
3. Cập nhật `REPO_NAME` trong file config

### Lỗi 4: "Deployment group not found"

**Nguyên nhân:** Deployment Group ID không đúng

**Giải pháp:**
1. Vào Azure DevOps → Pipelines → Deployment groups
2. Click vào deployment group
3. Xem URL: `...?poolId=XX`
4. Số `XX` là ID đúng

### Lỗi 5: Script không chạy trên PowerShell

**Nguyên nhân:** Execution policy chặn script

**Giải pháp:**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Lỗi 6: "No targets found matching the tags"

**Nguyên nhân:** Không có server nào trong deployment group có đủ tags được chỉ định

**Giải pháp:**
1. Vào Deployment Groups
2. Kiểm tra tags của các servers
3. Đảm bảo servers có **TẤT CẢ** tags được liệt kê trong config
4. Ví dụ: Nếu config có `"web-server,dev"` thì server phải có CẢ 2 tags này

### Lỗi 7: Pipeline import thành công nhưng không trigger tự động

**Nguyên nhân:** Branch filter chưa đúng hoặc continuous deployment trigger chưa bật

**Giải pháp:**
1. Vào pipeline → Edit
2. Click vào lightning icon trên artifact
3. Kiểm tra **Continuous deployment trigger** = Enabled
4. Kiểm tra **Build branch filters** có đúng các branch:
   - Development: `dev1`, `dev2`
   - Staging: `stage`
   - Production: `prod`

---

## Tùy Chỉnh Deployment Scripts

Mặc định, pipeline chạy scripts đơn giản để echo thông báo. Để thay đổi logic deployment:

### Bước 1: Mở file `release-definition.json`

### Bước 2: Tìm phần `workflowTasks` trong mỗi stage

Ví dụ cho Development stage:

```json
{
  "workflowTasks": [
    {
      "taskId": "d9bafed4-0b18-4f58-968d-86655b4d2ce9",
      "version": "2.*",
      "name": "Deploy to Development",
      "inputs": {
        "targetType": "inline",
        "script": "#!/bin/bash\necho \"Deploying to Development...\"\necho \"Server: $(hostname)\"\necho \"Working directory: $(pwd)\"\necho \"Artifact location: $(System.DefaultWorkingDirectory)\"\n\n# Thêm lệnh deployment của bạn ở đây\n# Ví dụ:\n# sudo systemctl stop myapp\n# sudo cp -r $(System.DefaultWorkingDirectory)/_MyApp/* /var/www/html/\n# sudo systemctl start myapp"
      }
    }
  ]
}
```

### Bước 3: Thay đổi script theo nhu cầu

Ví dụ deployment một ứng dụng Node.js:

```bash
#!/bin/bash
echo "=== Starting Deployment to Development ==="

# Dừng ứng dụng
echo "Stopping application..."
pm2 stop myapp

# Copy files mới
echo "Copying new files..."
cp -r $(System.DefaultWorkingDirectory)/_MyWebApp/drop/* /var/www/myapp/

# Cài đặt dependencies
echo "Installing dependencies..."
cd /var/www/myapp
npm install --production

# Chạy migrations (nếu có)
echo "Running database migrations..."
npm run migrate

# Khởi động lại ứng dụng
echo "Starting application..."
pm2 restart myapp

echo "=== Deployment completed successfully ==="
```

### Bước 4: Chạy lại script import để cập nhật pipeline

---

## Lưu Ý Bảo Mật

1. **KHÔNG commit file `config.local.sh` hoặc `config.local.ps1` lên Git** (đã có trong .gitignore)

2. **PAT Token:**
   - Lưu token ở nơi an toàn
   - Đặt thời gian hết hạn phù hợp
   - Không chia sẻ token với người khác
   - Xóa token khi không dùng nữa

3. **Deployment Scripts:**
   - Không hardcode passwords trong scripts
   - Sử dụng Azure Key Vault hoặc Variable Groups để lưu secrets
   - Sử dụng service connections cho authentication

---

## Các Tính Năng Nâng Cao

### Sử dụng Variable Groups

Thay vì hardcode giá trị trong scripts, bạn có thể dùng variable groups:

1. Vào Azure DevOps → Pipelines → Library
2. Tạo Variable Group mới
3. Thêm variables (ví dụ: DB_HOST, API_KEY, etc.)
4. Trong pipeline, link variable group vào từng stage
5. Sử dụng trong script: `$(DB_HOST)`, `$(API_KEY)`

### Approval Gates

Để yêu cầu approval trước khi deploy:

1. Vào pipeline → Edit
2. Click vào stage cần approval (ví dụ: Production)
3. Chọn **Pre-deployment conditions**
4. Enable **Pre-deployment approvals**
5. Thêm approvers

### Notifications

Cấu hình thông báo khi deployment thành công/thất bại:

1. Vào Project Settings → Notifications
2. Tạo subscription mới
3. Chọn event: Release deployment completed/failed
4. Chọn pipeline và email/Teams/Slack để nhận thông báo

---

## Hỗ Trợ

Nếu gặp vấn đề:

1. Đọc kỹ thông báo lỗi
2. Kiểm tra lại file config
3. Xem phần [Xử Lý Lỗi](#xử-lý-lỗi) ở trên
4. Kiểm tra logs trong Azure DevOps
5. Đọc file README.md (English) để biết thêm chi tiết

---

## Tổng Kết

Sau khi hoàn thành hướng dẫn, bạn đã có:

✅ Azure DevOps Release Pipeline tự động
✅ 3 stages: Development → Staging → Production
✅ Auto-trigger dựa trên branch
✅ Deployment Groups với tag filtering
✅ Inline deployment scripts
✅ Hỗ trợ pipeline và repo ở các project khác nhau

**Chúc bạn triển khai thành công!**
