# Hướng Dẫn Tạo Azure DevOps Release Pipeline

## ⭐ Tính Năng Nổi Bật

- ✅ **Nhiều Pipelines**: Tạo nhiều pipeline configurations với các file `.env` riêng biệt
- ✅ **An Toàn**: File `.env` được git-ignore tự động, không lo lộ PAT token
- ✅ **Linh Hoạt**: Cấu hình branches và deployment scripts dễ dàng
- ✅ **Cross-Platform**: Hỗ trợ cả Linux/Mac (Bash) và Windows (PowerShell)
- ✅ **Tự Động**: Script tự động fetch IDs, convert formats, import pipeline

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

### BƯỚC 1: Tạo File Cấu Hình (.env)

Solution này cho phép bạn tạo **nhiều pipelines khác nhau** với các file `.env` riêng biệt.

#### Copy template file:

**Linux/Mac:**
```bash
cd release-pipeline
cp pipelines.env.example pipelines.env
```

**Windows PowerShell:**
```powershell
cd release-pipeline
Copy-Item pipelines.env.example pipelines.env
```

#### Tạo nhiều pipelines (Optional):

Bạn có thể tạo nhiều file `.env` cho các pipelines khác nhau. Mỗi file có thể có tên pipeline riêng:

```bash
# Pipeline cho web application
cp pipelines.env.example web-app.env
# Trong file: PIPELINE_NAME="WebApp Release Pipeline"

# Pipeline cho API service
cp pipelines.env.example api-service.env
# Trong file: PIPELINE_NAME="API Service Release"

# Pipeline cho mobile backend
cp pipelines.env.example mobile-backend.env
# Trong file: PIPELINE_NAME="Mobile Backend Deployment"
```

**Lợi ích:** Mỗi pipeline sẽ có tên riêng trong Azure DevOps, dễ phân biệt và quản lý.

### BƯỚC 2: Chỉnh Sửa File Cấu Hình

**Linux/Mac:**
```bash
nano pipelines.env
# Hoặc dùng editor bạn thích: vim, code, gedit...
```

**Windows:**
```powershell
notepad pipelines.env
# Hoặc dùng: code pipelines.env
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

# Tên pipeline sẽ hiển thị trong Azure DevOps
PIPELINE_NAME="Multi-Stage Auto Release"

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

# ==========================================
# PHẦN 4: Cấu Hình Branch Triggers
# ==========================================

# Branch mặc định cho manual releases
DEFAULT_BRANCH="main"

# Development Stage - kích hoạt bởi các branches sau
DEVELOPMENT_BRANCHES="dev1,dev2"

# Staging Stage - kích hoạt bởi branch
STAGING_BRANCHES="stage"

# Production Stage - kích hoạt bởi branch
PRODUCTION_BRANCHES="prod"

# ==========================================
# PHẦN 5: Deployment Scripts
# ==========================================

# Development Stage Script
DEVELOPMENT_SCRIPT='#!/bin/bash
echo "=========================================="
echo "Starting Deployment to Development"
echo "=========================================="
echo "Server: $(hostname)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "Artifact location: $(System.DefaultWorkingDirectory)"
echo ""

# Thêm lệnh deployment của bạn ở đây
# Ví dụ:
# sudo systemctl stop myapp-dev
# sudo cp -r $(System.DefaultWorkingDirectory)/_MyApp/drop/* /var/www/dev/
# sudo chown -R www-data:www-data /var/www/dev/
# sudo systemctl start myapp-dev

echo "Deployment to Development completed successfully!"
echo "=========================================="'

# Staging Stage Script
STAGING_SCRIPT='#!/bin/bash
echo "=========================================="
echo "Starting Deployment to Staging"
echo "=========================================="
# ... Lệnh deployment cho Staging ...
echo "=========================================="'

# Production Stage Script
PRODUCTION_SCRIPT='#!/bin/bash
echo "=========================================="
echo "Starting Deployment to Production"
echo "=========================================="
# ... Lệnh deployment cho Production ...
echo "=========================================="'
```

#### Ví Dụ Cấu Hình Thực Tế:

```bash
ORGANIZATION_NAME="contoso"
PAT_TOKEN="abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx"

# Tên pipeline
PIPELINE_NAME="WebApp Production Release"

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

# Branch triggers
DEVELOPMENT_BRANCHES="dev1,dev2,develop"
STAGING_BRANCHES="stage,staging"
PRODUCTION_BRANCHES="prod,main"

# Deployment scripts - sử dụng scripts mặc định hoặc tùy chỉnh
```

**LƯU Ý về Tags:**
- Các tags cách nhau bởi dấu phẩy (không có khoảng trắng)
- Tags phải khớp với tags đã gán cho servers trong deployment group
- Pipeline chỉ chạy trên servers có **TẤT CẢ** các tags được chỉ định

**LƯU Ý về Branches:**
- Các branches cách nhau bởi dấu phẩy (không có khoảng trắng)
- Khi code được push/merge vào một trong các branches này, pipeline sẽ tự động trigger stage tương ứng
- Ví dụ: Push vào `dev1` hoặc `dev2` → Deploy tự động vào Development stage
- Bạn có thể thêm nhiều branches cho mỗi stage: `"dev1,dev2,dev3,develop"`

**LƯU Ý về Deployment Scripts:**
- Scripts được viết bằng Bash shell script
- Sử dụng single quotes `'...'` để bọc multiline scripts
- Có thể sử dụng các biến Azure DevOps như `$(System.DefaultWorkingDirectory)`, `$(Build.SourceBranch)`, etc.
- Scripts mặc định chỉ echo thông tin - bạn cần thêm lệnh deployment thực tế
- Ví dụ lệnh deployment: stop service, copy files, restart service, run migrations, etc.

### BƯỚC 4: Lưu File Cấu Hình

- Trong `nano`: Nhấn `Ctrl+O` để lưu, `Ctrl+X` để thoát
- Trong `notepad`: Nhấn `Ctrl+S` để lưu
- Trong `vim`: Nhấn `Esc`, gõ `:wq`, nhấn `Enter`

### BƯỚC 5: Chạy Script Import

#### Với Linux/Mac:

```bash
# Cấp quyền thực thi cho script (chỉ cần làm 1 lần)
chmod +x import-release-pipeline.sh

# Chạy script với file .env mặc định (pipelines.env)
./import-release-pipeline.sh

# HOẶC chỉ định file .env cụ thể
./import-release-pipeline.sh web-app.env
./import-release-pipeline.sh api-service.env

# Xem hướng dẫn sử dụng
./import-release-pipeline.sh --help
```

#### Với Windows PowerShell:

```powershell
# Có thể cần cho phép chạy script (chỉ cần làm 1 lần)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Chạy script với file .env mặc định (pipelines.env)
.\import-release-pipeline.ps1

# HOẶC chỉ định file .env cụ thể
.\import-release-pipeline.ps1 -EnvFile web-app.env
.\import-release-pipeline.ps1 -EnvFile api-service.env

# Xem hướng dẫn sử dụng
.\import-release-pipeline.ps1 -Help
```

#### Ví Dụ Workflow Nhiều Pipelines:

```bash
# Tạo và cấu hình 3 pipelines khác nhau
cp pipelines.env.example web-frontend.env
cp pipelines.env.example api-backend.env
cp pipelines.env.example mobile-api.env

# Chỉnh sửa từng file với thông tin riêng
nano web-frontend.env   # Cấu hình cho web
nano api-backend.env    # Cấu hình cho API
nano mobile-api.env     # Cấu hình cho mobile

# Import lần lượt từng pipeline
./import-release-pipeline.sh web-frontend.env
./import-release-pipeline.sh api-backend.env
./import-release-pipeline.sh mobile-api.env
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
   - ✅ Build branch filters (theo cấu hình của bạn):
     - Branches trong `DEVELOPMENT_BRANCHES` → Development stage
     - Branches trong `STAGING_BRANCHES` → Staging stage
     - Branches trong `PRODUCTION_BRANCHES` → Production stage

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
1. Commit code vào một trong các branches trong `DEVELOPMENT_BRANCHES` (mặc định: `dev1` hoặc `dev2`)
2. Pipeline tự động trigger stage Development
3. Commit vào branch trong `STAGING_BRANCHES` (mặc định: `stage`) → trigger Staging
4. Commit vào branch trong `PRODUCTION_BRANCHES` (mặc định: `prod`) → trigger Production

**Lưu ý:** Branches trigger được cấu hình trong file config của bạn!

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
4. Kiểm tra **Build branch filters** có đúng các branch theo config của bạn:
   - Development: branches trong `DEVELOPMENT_BRANCHES`
   - Staging: branches trong `STAGING_BRANCHES`
   - Production: branches trong `PRODUCTION_BRANCHES`
5. Đảm bảo bạn đang push code vào đúng branch name (có phân biệt hoa/thường)

---

## Tùy Chỉnh Deployment Scripts

Mặc định, pipeline chạy scripts đơn giản để echo thông báo. Để thay đổi logic deployment:

### Phương Án 1: Sửa Trong File Config (Khuyến Nghị)

Đây là cách dễ nhất và được khuyến nghị.

#### Bước 1: Mở file config

**Linux/Mac:**
```bash
nano config.local.sh
# hoặc
code config.local.sh
```

**Windows:**
```powershell
notepad config.local.ps1
# hoặc
code config.local.ps1
```

#### Bước 2: Tìm và sửa deployment scripts

Tìm các biến `DEVELOPMENT_SCRIPT`, `STAGING_SCRIPT`, `PRODUCTION_SCRIPT` và thay đổi nội dung:

**Ví dụ cho Development - Deployment ứng dụng Node.js:**

```bash
DEVELOPMENT_SCRIPT='#!/bin/bash
echo "=========================================="
echo "Starting Deployment to Development"
echo "=========================================="
echo "Server: $(hostname)"
echo "Date: $(date)"
echo ""

# Dừng ứng dụng
echo "Stopping application..."
pm2 stop myapp-dev

# Backup version hiện tại
echo "Creating backup..."
sudo cp -r /var/www/dev /var/www/dev.backup.$(date +%Y%m%d_%H%M%S)

# Copy files mới từ artifact
echo "Copying new files..."
sudo cp -r $(System.DefaultWorkingDirectory)/_MyWebApp/drop/* /var/www/dev/

# Set permissions
echo "Setting permissions..."
sudo chown -R www-data:www-data /var/www/dev/

# Cài đặt dependencies
echo "Installing dependencies..."
cd /var/www/dev
npm install --production

# Chạy migrations
echo "Running database migrations..."
npm run migrate

# Khởi động lại ứng dụng
echo "Starting application..."
pm2 start /var/www/dev/app.js --name myapp-dev

echo "Deployment to Development completed successfully!"
echo "=========================================="'
```

**Ví dụ cho Production - Deployment ứng dụng Python/Django:**

```bash
PRODUCTION_SCRIPT='#!/bin/bash
set -e  # Exit on error

echo "=========================================="
echo "Starting Deployment to Production"
echo "=========================================="
echo "Server: $(hostname)"
echo "Date: $(date)"
echo ""

# Kích hoạt virtual environment
source /var/www/production/venv/bin/activate

# Dừng service
echo "Stopping service..."
sudo systemctl stop myapp

# Backup
echo "Creating backup..."
sudo tar -czf /var/backups/myapp-$(date +%Y%m%d_%H%M%S).tar.gz /var/www/production/

# Copy files mới
echo "Deploying new version..."
sudo cp -r $(System.DefaultWorkingDirectory)/_MyApp/drop/* /var/www/production/

# Install dependencies
echo "Installing dependencies..."
cd /var/www/production
pip install -r requirements.txt

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Run migrations
echo "Running migrations..."
python manage.py migrate

# Restart service
echo "Starting service..."
sudo systemctl start myapp

# Health check
echo "Running health check..."
sleep 5
curl -f http://localhost:8000/health || exit 1

echo "Production deployment completed successfully!"
echo "=========================================="'
```

#### Bước 3: Lưu file và chạy lại import script

```bash
# Linux/Mac
./import-release-pipeline.sh

# Windows PowerShell
.\import-release-pipeline.ps1
```

Script sẽ tạo lại pipeline với deployment scripts mới.

### Phương Án 2: Sửa Trực Tiếp Trong Azure DevOps

Sau khi import pipeline, bạn có thể sửa scripts trực tiếp trong Azure DevOps:

1. Vào Azure DevOps → Pipelines → Releases
2. Chọn pipeline **Multi-Stage Auto Release**
3. Click **Edit**
4. Click vào stage muốn sửa (ví dụ: Development)
5. Click vào task **Deploy to Development**
6. Sửa nội dung trong field **Script**
7. Click **Save**

**Lưu ý:** Nếu bạn chạy lại import script, những thay đổi này sẽ bị ghi đè.

---

## Lưu Ý Bảo Mật

1. **KHÔNG commit file `.env` lên Git**
   - Tất cả `*.env` files đã được thêm vào `.gitignore` tự động
   - Chỉ commit file `*.env.example` (template không có giá trị thực)
   - Kiểm tra trước khi commit: `git status` (không thấy file `.env` là đúng)

2. **PAT Token:**
   - Lưu token ở nơi an toàn (password manager, Azure Key Vault)
   - Đặt thời gian hết hạn phù hợp (khuyến nghị: 30-90 ngày)
   - Không chia sẻ token với người khác
   - Xóa token khỏi Azure DevOps khi không dùng nữa
   - Nếu token bị lộ: Xóa ngay và tạo token mới

3. **Deployment Scripts:**
   - Không hardcode passwords/secrets trong scripts
   - Sử dụng Azure Key Vault hoặc Variable Groups để lưu secrets
   - Sử dụng service connections cho authentication với external services
   - Sử dụng Managed Identities khi có thể

4. **File `.env` Management:**
   - Mỗi developer có file `.env` riêng với PAT token của mình
   - Không share file `.env` qua email/chat
   - Backup file `.env` vào nơi an toàn (encrypted storage)
   - Sử dụng tên file rõ ràng: `web-app-prod.env`, `api-staging.env`

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
