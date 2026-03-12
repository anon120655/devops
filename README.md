# 🚀 CI/CD Templates (Reusable Workflows)

ระบบ CI/CD กลางสำหรับองค์กร — แก้ไขที่เดียว ทุก project อัพเดตตาม!

> ✅ **Organization**: ตั้งค่าเป็น `anon120655` แล้ว

---

## ⚡ Quick Install

### Linux / Mac

```bash
# Angular
git clone git@github.com:anon120655/devops.git /tmp/cicd && /tmp/cicd/install.sh angular && rm -rf /tmp/cicd

# Spring Boot
git clone git@github.com:anon120655/devops.git /tmp/cicd && /tmp/cicd/install.sh springboot && rm -rf /tmp/cicd
```

### Windows (PowerShell)

```powershell
# Angular
Remove-Item -Recurse -Force C:\tmp\cicd -ErrorAction SilentlyContinue; git clone git@github.com:anon120655/devops.git C:\tmp\cicd; & "C:\Program Files\Git\bin\bash.exe" C:\tmp\cicd\install.sh angular; Remove-Item -Recurse -Force C:\tmp\cicd

# Spring Boot
Remove-Item -Recurse -Force C:\tmp\cicd -ErrorAction SilentlyContinue; git clone git@github.com:anon120655/devops.git C:\tmp\cicd; & "C:\Program Files\Git\bin\bash.exe" C:\tmp\cicd\install.sh springboot; Remove-Item -Recurse -Force C:\tmp\cicd
```

> 💡 **หมายเหตุ**: Windows ต้องมี [Git for Windows](https://git-scm.com/download/win) ติดตั้งอยู่ (ใช้ `bash.exe` ที่มาพร้อม Git)

---

## 📂 Available Templates

| Framework | CI | Deploy |
|-----------|-----|--------|
| **Angular** | Lint, Build | SSH + Static Files (rsync) |
| **Spring Boot** | Maven/Gradle Build, Test | SSH + WAR/Tomcat |

---

## 🏗️ Architecture

### Reusable Workflows (workflow_call)

แทนที่จะ copy workflow ยาวๆ ไปทุก project เราใช้ **Reusable Workflows**:

```
devops/.github/workflows/          ← Reusable templates (แก้ที่นี่ที่เดียว)
├── angular-ci.yml
├── angular-deploy.yml
├── springboot-ci.yml
└── springboot-deploy.yml

your-project/.github/workflows/   ← Caller workflows (สั้นมาก ~15-25 บรรทัด)
├── ci.yml                         เรียกใช้ reusable template
└── deploy.yml
```

### ตัวอย่าง Caller Workflow (สิ่งที่ติดตั้งใน project)

```yaml
# ci.yml - เพียง 15 บรรทัด!
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  quality:
    uses: anon120655/devops/.github/workflows/angular-ci.yml@main
    with:
      node-version: '16'
```

---

## 🔧 Setup Guide

### 1. ติดตั้ง Template

```bash
cd /path/to/your/project
git clone git@github.com:anon120655/devops.git /tmp/cicd && /tmp/cicd/install.sh angular && rm -rf /tmp/cicd
```

### 2. ตรวจสอบ Organization Name

ไฟล์ `.github/workflows/ci.yml` และ `deploy.yml` ถูกตั้งค่า Organization เป็น `anon120655` แล้ว:

```yaml
jobs:
  quality:
    uses: anon120655/devops/.github/workflows/angular-ci.yml@main
    #     ^^^^^^^^ แก้ตรงนี้
```

### 3. แก้ไข deploy.yml

#### Angular

```yaml
with:
  deploy-path: '/home/locus/public_html_uat'    # ← path บน server
  angular-build-configuration: 'uat'            # ← build config
  prebuild-script: 'npm run prebuild.uat'       # ← (optional) script ก่อน build
  dist-subfolder: 'thaihealth-eform'            # ← subfolder ใน dist/
```

#### Spring Boot

```yaml
with:
  war-filename: 'thaihealth-eform-backend.war'  # ← ชื่อไฟล์ WAR
  tomcat-webapps-path: '/opt/tomcat/webapps'    # ← path webapps
  deploy-staging-path: '/home/locus/deploy'     # ← path วาง WAR ชั่วคราว
  tomcat-service-name: 'tomcat'                 # ← ชื่อ service
```

### 4. เพิ่ม GitHub Secrets

ไปที่ **Settings > Secrets and variables > Actions** ของ project repo และเพิ่ม:

| Secret | Description |
|--------|-------------|
| `SSH_PRIVATE_KEY` | Private key สำหรับ SSH (ต้องมีบรรทัด BEGIN/END) |
| `SSH_HOST` | Server IP/hostname (เช่น 10.10.1.28) |
| `SSH_USERNAME` | Username บน server (เช่น locus) |
| `SSH_PORT` | Port (default: 22, ไม่ต้องตั้งถ้าใช้ 22) |

### 5. ตั้งค่า Permissions (สำคัญ!)

เนื่องจาก reusable workflows อยู่ใน repo แยก (devops) ต้องตั้งค่าให้ repos อื่นเข้าถึงได้:

1. ไปที่ **anon120655/devops** repo
2. Settings > Actions > General
3. เลือก **"Allow access to repositories in the anon120655 organization"**

### 6. ตั้งค่า Self-hosted Runner (ถ้าต้องเชื่อม VPN)

ถ้า server อยู่หลัง VPN ต้องติดตั้ง GitHub Actions Runner บนเครื่องที่เชื่อม VPN:

```bash
# ไปที่ GitHub repo > Settings > Actions > Runners > New self-hosted runner
# แล้วทำตาม instructions ที่ GitHub ให้มา

# Download
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.xxx.x.tar.gz -L https://github.com/actions/runner/releases/download/v2.xxx.x/actions-runner-linux-x64-2.xxx.x.tar.gz
tar xzf ./actions-runner-linux-x64-2.xxx.x.tar.gz

# Configure
./config.sh --url https://github.com/anon120655/your-repo --token YOUR_TOKEN

# Run as service
sudo ./svc.sh install
sudo ./svc.sh start
```

### 7. Push และทดสอบ

```bash
# CI จะ trigger ทุกครั้งที่ push
git add .github/
git commit -m "Add CI/CD workflows"
git push

# Deploy จะ trigger เมื่อสร้าง tag
git tag v1.0.0
git push origin v1.0.0
```

---

## 📁 Folder Structure

```
devops/
├── .github/workflows/              # Reusable templates (workflow_call)
│   ├── angular-ci.yml              #   Angular: lint + build
│   ├── angular-deploy.yml          #   Angular: build + rsync ไป server
│   ├── springboot-ci.yml           #   Spring Boot: build + test
│   └── springboot-deploy.yml       #   Spring Boot: build WAR + deploy Tomcat
├── examples/                       # Caller workflow examples
│   ├── angular/.github/workflows/
│   │   ├── ci.yml
│   │   └── deploy.yml
│   └── springboot/.github/workflows/
│       ├── ci.yml
│       └── deploy.yml
├── install.sh                      # Installer script
└── README.md                       # คู่มือนี้
```

---

## 📊 Inputs Reference

### angular-ci.yml
| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `node-version` | string | `'16'` | Node.js version |
| `angular-build-configuration` | string | `'production'` | Build configuration |
| `runs-on` | string | `'self-hosted'` | Runner |

### angular-deploy.yml
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `deploy-path` | string | ✅ | Path บน server สำหรับวาง static files |
| `node-version` | string | | Node.js version (default: 16) |
| `angular-build-configuration` | string | | Build config: uat, production |
| `prebuild-script` | string | | Script ก่อน build (เช่น npm run prebuild.uat) |
| `dist-subfolder` | string | | Subfolder ใน dist/ (ดูจาก angular.json) |
| `health-url` | string | | Health check URL (optional) |
| `runs-on` | string | | Runner (default: self-hosted) |

### springboot-ci.yml
| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `java-version` | string | `'17'` | Java version |
| `java-distribution` | string | `'temurin'` | Java distribution |
| `build-tool` | string | `'maven'` | Build tool: maven or gradle |
| `runs-on` | string | `'self-hosted'` | Runner |

### springboot-deploy.yml
| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `war-filename` | string | ✅ | ชื่อไฟล์ WAR (e.g., app-backend.war) |
| `java-version` | string | | Java version (default: 17) |
| `build-tool` | string | | Build tool: maven or gradle |
| `tomcat-webapps-path` | string | | Tomcat webapps path (default: /opt/tomcat/webapps) |
| `deploy-staging-path` | string | | Path วาง WAR ชั่วคราว (default: /home/locus/deploy) |
| `tomcat-service-name` | string | | ชื่อ Tomcat service (default: tomcat) |
| `health-url` | string | | Health check URL (optional) |
| `runs-on` | string | | Runner (default: self-hosted) |

### Secrets (ใช้ร่วมกันทั้ง Angular และ Spring Boot)
| Secret | Required | Description |
|--------|----------|-------------|
| `SSH_PRIVATE_KEY` | ✅ | Private key สำหรับ SSH |
| `SSH_HOST` | ✅ | Server IP/hostname |
| `SSH_USERNAME` | ✅ | Username บน server |
| `SSH_PORT` | | Port SSH (default: 22) |

---

## 🏆 Benefits

1. **Single Source of Truth**: แก้ปัญหา/เพิ่มฟีเจอร์ที่เดียว ทุก project อัพเดตตาม
2. **Cleaner Repositories**: ไฟล์ workflow ในแต่ละ project สั้นมาก (~15-25 บรรทัด)
3. **Governance**: ควบคุมมาตรฐาน CI/CD ทั้งองค์กรได้เป๊ะ
4. **Easy Onboarding**: project ใหม่แค่รัน install.sh เสร็จภายใน 5 นาที

---

## 📝 Changelog

- **2026-03-12**: 🎉 Initial release
  - ✅ angular-ci.yml / angular-deploy.yml (SSH + Static Files)
  - ✅ springboot-ci.yml / springboot-deploy.yml (SSH + WAR/Tomcat)
  - ✅ Installer script (install.sh)
  - ✅ Example caller workflows
