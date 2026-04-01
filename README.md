# CI/CD Templates (Reusable Workflows)

ระบบ CI/CD กลางสำหรับองค์กร — แก้ไขที่เดียว ทุก project อัพเดตตาม!

> **Organization**: ตั้งค่าเป็น `anon120655` แล้ว

---

## Quick Install

### Linux / Mac

```bash
# Angular
git clone git@github.com:anon120655/devops.git /tmp/cicd && /tmp/cicd/install.sh angular && rm -rf /tmp/cicd

# Spring Boot
git clone git@github.com:anon120655/devops.git /tmp/cicd && /tmp/cicd/install.sh springboot && rm -rf /tmp/cicd

# .NET (ASP.NET Core — publish + SSH + systemd)
git clone git@github.com:anon120655/devops.git /tmp/cicd && /tmp/cicd/install.sh dotnet && rm -rf /tmp/cicd
```

### Windows (PowerShell)

```powershell
# Angular
Remove-Item -Recurse -Force C:\tmp\cicd -ErrorAction SilentlyContinue; git clone git@github.com:anon120655/devops.git C:\tmp\cicd; & "C:\Program Files\Git\bin\bash.exe" C:\tmp\cicd\install.sh angular; Remove-Item -Recurse -Force C:\tmp\cicd

# Spring Boot
Remove-Item -Recurse -Force C:\tmp\cicd -ErrorAction SilentlyContinue; git clone git@github.com:anon120655/devops.git C:\tmp\cicd; & "C:\Program Files\Git\bin\bash.exe" C:\tmp\cicd\install.sh springboot; Remove-Item -Recurse -Force C:\tmp\cicd

# .NET
Remove-Item -Recurse -Force C:\tmp\cicd -ErrorAction SilentlyContinue; git clone git@github.com:anon120655/devops.git C:\tmp\cicd; & "C:\Program Files\Git\bin\bash.exe" C:\tmp\cicd\install.sh dotnet; Remove-Item -Recurse -Force C:\tmp\cicd
```

> **หมายเหตุ**: Windows ต้องมี [Git for Windows](https://git-scm.com/download/win) ติดตั้งอยู่ (ใช้ `bash.exe` ที่มาพร้อม Git)

---

## Available Templates

| Framework | CI | Deploy |
|-----------|-----|--------|
| **Angular** | Lint, Build | SSH + Static Files (rsync) |
| **Spring Boot** | Maven Build | SSH + WAR/Tomcat |
| **.NET** | Restore + Build | `dotnet publish` + SSH rsync + `systemctl restart` |

---

## Architecture

### Reusable Workflows (workflow_call)

แทนที่จะ copy workflow ยาวๆ ไปทุก project เราใช้ **Reusable Workflows**:

```
devops/.github/workflows/          ← Reusable templates (แก้ที่นี่ที่เดียว)
├── angular-ci.yml
├── angular-deploy.yml
├── springboot-ci.yml
├── springboot-deploy.yml
├── dotnet-ci.yml
└── dotnet-deploy.yml

your-project/.github/workflows/   ← Caller workflows (สั้นมาก ~15-30 บรรทัด)
├── ci.yml                         เรียกใช้ reusable template
├── deploy-uat.yml                 สำหรับ Deploy ขึ้น UAT (workflow_dispatch)
├── deploy-prod.yml                สำหรับ Deploy ขึ้น Production (tag v*)
└── test-ssh.yml                   ทดสอบ SSH ก่อน Deploy จริง (ลบได้หลังทดสอบสำเร็จ)
```

### ตัวอย่าง Caller Workflow (สิ่งที่ติดตั้งใน project)

```yaml
# ci.yml
name: CI

on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  quality:
    uses: anon120655/devops/.github/workflows/angular-ci.yml@main
    with:
      node-version: '16'
      angular-build-configuration: 'production'
      runs-on: 'self-hosted'
```

---

## Setup Guide

### 1. ติดตั้ง Template

```bash
cd /path/to/your/project
git clone git@github.com:anon120655/devops.git /tmp/cicd && /tmp/cicd/install.sh angular && rm -rf /tmp/cicd
```

### 2. ตรวจสอบ Organization Name

ไฟล์ `.github/workflows/ci.yml`, `deploy-uat.yml` และ `deploy-prod.yml` ถูกตั้งค่า Organization เป็น `anon120655` แล้ว:

```yaml
jobs:
  quality:
    uses: anon120655/devops/.github/workflows/angular-ci.yml@main
    #     ^^^^^^^^ แก้ตรงนี้ถ้า org ไม่ใช่ anon120655
```

### 3. แก้ไขไฟล์ Deploy (deploy-uat.yml, deploy-prod.yml)

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
  maven-profile: 'prod'                            # ← Maven profile (prod, uat, dev)
  war-filename: 'thaihealth-eform-backend.war'      # ← ชื่อไฟล์ WAR
  tomcat-webapps-path: '/opt/tomcat/webapps'        # ← path webapps
  deploy-staging-path: '/home/locus/deploy'         # ← path วาง WAR ชั่วคราว
  tomcat-service-name: 'tomcat'                     # ← ชื่อ service
```

#### .NET (ASP.NET Core)

ติดตั้งด้วย `install.sh dotnet` จะได้ตัวอย่างหลายไฟล์ — เลือกใช้ตาม repo (API แยก / Web แยก) แล้วลบไฟล์ที่ไม่ใช้ออก

```yaml
# CI (ใช้ร่วมได้ทั้งโปรเจกต์)
with:
  dotnet-version: '6.0.x'
  csproj-path: 'YourApp.API.csproj'
  target-framework: 'net6.0'
  runtime-identifier: 'linux-x64'   # หรือ win-x64; ว่าง = build/publish ไม่ใส่ -r

# Deploy
with:
  dotnet-version: '6.0.x'
  csproj-path: 'YourApp.API.csproj'
  target-framework: 'net6.0'
  runtime-identifier: 'linux-x64'
  self-contained: false
  project-kind: 'backend'           # frontend = ลบ wwwroot/appkeys + wwwroot/files ก่อน sync
  deploy-path: '/home/ibusiness/publish'
  systemd-service: 'kestrel-helloapp_api.service'
```

**Runner**: job deploy ใช้ `ssh` + `rsync` — แนะนำ **Linux หรือ macOS self-hosted runner** (หรือ runner ที่มีเครื่องมือเหล่านี้) หากใช้ Windows runner ต้องมี OpenSSH/rsync ให้ครบเอง

**Server**: ต้องตั้ง `sudoers` ให้ user ที่ deploy รัน `systemctl restart <unit>` แบบ NOPASSWD (เหมือน Spring Boot/Tomcat)

### 4. เพิ่ม GitHub Secrets

ไปที่ **Settings > Secrets and variables > Actions** ของ project repo และเพิ่ม:

Secrets ต้องแยก **UAT** กับ **PROD** โดยใช้ prefix ตาม environment:

| Secret (UAT) | Secret (PROD) | Description |
|---------------|---------------|-------------|
| `UAT_SSH_PRIVATE_KEY` | `PROD_SSH_PRIVATE_KEY` | Private key สำหรับ SSH (ต้องมีบรรทัด BEGIN/END) |
| `UAT_SSH_HOST` | `PROD_SSH_HOST` | Server IP/hostname (เช่น 10.10.1.28) |
| `UAT_SSH_USERNAME` | `PROD_SSH_USERNAME` | Username บน server (เช่น locus) |
| `UAT_SSH_PORT` | `PROD_SSH_PORT` | Port SSH (default: 22) |
| | | **ไม่ต้องใช้ password** — ตั้ง sudoers NOPASSWD บน server แทน (ดู Server Setup) |

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

### 7. ทดสอบ SSH ก่อน Deploy

ใช้ `test-ssh.yml` ที่ติดตั้งมาพร้อมกัน:

1. ไปที่ **Actions** tab ของ project repo
2. เลือก **Test SSH Connection**
3. กด **Run workflow**
4. ถ้า SSH ผ่านแล้ว ลบไฟล์ `test-ssh.yml` ออกได้

### 8. Push และ Deploy

```bash
# CI จะ trigger ทุกครั้งที่ push ไป master
git add .github/
git commit -m "Add CI/CD workflows"
git push

# Deploy UAT → กดปุ่ม "Run workflow" ในหน้า Actions (workflow_dispatch)

# Deploy PROD → สร้าง tag
git tag v1.0.0
git push origin v1.0.0
```

---

## Folder Structure

```
devops/
├── .github/workflows/              # Reusable templates (workflow_call)
│   ├── angular-ci.yml              #   Angular: lint + build
│   ├── angular-deploy.yml          #   Angular: build + rsync ไป server
│   ├── springboot-ci.yml           #   Spring Boot: maven build
│   ├── springboot-deploy.yml       #   Spring Boot: build WAR + deploy Tomcat
│   ├── dotnet-ci.yml               #   .NET: restore + build
│   └── dotnet-deploy.yml           #   .NET: publish + rsync + systemd
├── examples/                       # Caller workflow examples
│   ├── angular/.github/workflows/
│   │   ├── ci.yml
│   │   ├── deploy-uat.yml
│   │   ├── deploy-prod.yml
│   │   └── test-ssh.yml
│   └── springboot/.github/workflows/
│       ├── ci.yml
│       ├── deploy-uat.yml
│       ├── deploy-prod.yml
│       └── test-ssh.yml
│   └── dotnet/.github/workflows/
│       ├── ci.yml
│       ├── deploy-uat-backend.yml
│       ├── deploy-prod-backend.yml
│       ├── deploy-uat-frontend.yml
│       ├── deploy-prod-frontend.yml
│       └── test-ssh.yml
├── install.sh                      # Installer script
└── README.md                       # คู่มือนี้
```

---

## Inputs Reference

### angular-ci.yml

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `node-version` | string | `'16'` | Node.js version |
| `angular-build-configuration` | string | `'production'` | Build configuration |
| `runs-on` | string | `'self-hosted'` | Runner |

### angular-deploy.yml

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `deploy-path` | string | **required** | — | Path บน server สำหรับวาง static files |
| `node-version` | string | | `'16'` | Node.js version |
| `angular-build-configuration` | string | | `'production'` | Build config: uat, production |
| `prebuild-script` | string | | `''` | Script ก่อน build (เช่น npm run prebuild.uat) |
| `dist-subfolder` | string | | `''` | Subfolder ใน dist/ (ดูจาก angular.json) |
| `runs-on` | string | | `'self-hosted'` | Runner |

### springboot-ci.yml

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `java-version` | string | `'17'` | Java version |
| `java-distribution` | string | `'temurin'` | Java distribution |
| `maven-profile` | string | `'prod'` | Maven profile (e.g., prod, uat, dev) |
| `runs-on` | string | `'self-hosted'` | Runner |

### springboot-deploy.yml

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `war-filename` | string | **required** | — | ชื่อไฟล์ WAR (e.g., app-backend.war) |
| `java-version` | string | | `'17'` | Java version |
| `java-distribution` | string | | `'temurin'` | Java distribution |
| `maven-profile` | string | | `'prod'` | Maven profile (e.g., prod, uat, dev) |
| `tomcat-webapps-path` | string | | `'/opt/tomcat/webapps'` | Tomcat webapps path |
| `deploy-staging-path` | string | | `'/home/locus/deploy'` | Path วาง WAR ชั่วคราว |
| `tomcat-service-name` | string | | `'tomcat'` | ชื่อ Tomcat service |
| `runs-on` | string | | `'self-hosted'` | Runner |

### dotnet-ci.yml

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `dotnet-version` | string | **required** | เวอร์ชัน SDK (เช่น `6.0.x`, `8.0.x`) |
| `csproj-path` | string | **required** | path ไปยัง `.csproj` จาก root ของ working-directory |
| `target-framework` | string | **required** | TFM (เช่น `net6.0`, `net8.0`) |
| `runtime-identifier` | string | `linux-x64` | RID สำหรับ `dotnet build -r`; ว่าง = ไม่ส่ง `-r` |
| `build-configuration` | string | `Release` | configuration |
| `working-directory` | string | `.` | โฟลเดอร์ทำงาน (monorepo) |
| `runs-on` | string | `self-hosted` | Runner |

### dotnet-deploy.yml

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `dotnet-version` | string | **required** | — | SDK version |
| `csproj-path` | string | **required** | — | Path ไปยัง `.csproj` |
| `target-framework` | string | **required** | — | TFM สำหรับ `-f` และ path publish |
| `runtime-identifier` | string | | `linux-x64` | RID สำหรับ publish; ว่าง = ไม่ส่ง `-r` |
| `self-contained` | boolean | | `false` | self-contained publish |
| `project-kind` | string | | `backend` | `frontend` = ลบ `wwwroot/appkeys`, `wwwroot/files` จาก artifact ก่อน rsync |
| `deploy-path` | string | **required** | — | path ปลายทางบน Linux server |
| `systemd-service` | string | **required** | — | unit ที่รัน `sudo systemctl restart` |
| `working-directory` | string | | `.` | working directory |
| `backup-remote` | boolean | | `true` | backup โฟลเดอร์ปลายทางก่อน sync |
| `rsync-delete` | boolean | | `false` | ส่ง `--delete` ให้ rsync |
| `runs-on` | string | | `self-hosted` | Runner |

### Secrets (ใช้ร่วมกันกับ Deploy แบบ SSH: Angular, Spring Boot, .NET)

| Secret | Required | Description |
|--------|----------|-------------|
| `SSH_PRIVATE_KEY` | **required** | Private key สำหรับ SSH |
| `SSH_HOST` | **required** | Server IP/hostname |
| `SSH_USERNAME` | **required** | Username บน server |
| `SSH_PORT` | | Port SSH (default: 22) |
| | | **ไม่ต้องใช้ password** — ตั้ง sudoers NOPASSWD บน server แทน |

> **หมายเหตุ**: ใน caller workflow ให้ใช้ prefix `UAT_` หรือ `PROD_` เช่น `${{ secrets.UAT_SSH_HOST }}` / `${{ secrets.PROD_SSH_HOST }}` — **.NET deploy ใช้ชุด secrets เดียวกันนี้**

---

## Deploy Flow

### Angular

```
Checkout → Setup Node.js → npm ci → Prebuild (optional) → ng build
→ Setup SSH → Backup เว็บเดิม → rsync ไป /tmp → su deploy ไป target path → Cleanup
```

### Spring Boot

```
Checkout → Setup Java → mvnw clean package → Setup SSH
→ Backup WAR เดิม → scp WAR ไป /tmp → su ย้ายไป staging
→ su stop Tomcat → replace WAR → start Tomcat → Cleanup
```

### .NET

```
Checkout → Setup .NET → dotnet publish → (frontend: strip wwwroot folders) → Setup SSH
→ (optional) backup remote deploy-path → rsync publish/ → sudo systemctl restart → Cleanup
```

---

## Benefits

1. **Single Source of Truth**: แก้ปัญหา/เพิ่มฟีเจอร์ที่เดียว ทุก project อัพเดตตาม
2. **Cleaner Repositories**: ไฟล์ workflow ในแต่ละ project สั้นมาก (~15-30 บรรทัด)
3. **Governance**: ควบคุมมาตรฐาน CI/CD ทั้งองค์กรได้
4. **Easy Onboarding**: project ใหม่แค่รัน install.sh เสร็จภายใน 5 นาที
5. **Automatic Backup**: ทั้ง Angular และ Spring Boot จะ backup ของเดิมก่อน deploy ทุกครั้ง

---

## Changelog

- **2026-04-01**: เพิ่ม .NET reusable workflows (`dotnet-ci.yml`, `dotnet-deploy.yml`)
  - พารามิเตอร์ `dotnet-version`, `target-framework`, `runtime-identifier` (default `linux-x64`, ว่างได้ = ไม่ใส่ `-r`)
  - Deploy: `dotnet publish` + rsync + `systemctl restart`; `project-kind: frontend` ลบ `wwwroot/appkeys` และ `wwwroot/files` ก่อน sync
  - ตัวอย่าง caller ใน `examples/dotnet/` (แยก UAT/PROD และ backend/frontend), `install.sh dotnet`, อัปเดต README

- **2026-03-30**: ปรับปรุง README ให้ตรงกับ workflow ปัจจุบัน
  - แก้ Inputs Reference ให้ตรงกับ YAML จริง (`maven-profile` แทน `build-tool`, ลบ `health-url` ที่ไม่มี)
  - เปลี่ยนจาก `SU_PASSWORD` เป็น sudoers NOPASSWD (ไม่ต้องส่ง password แล้ว)
  - เพิ่ม `test-ssh.yml` ใน folder structure และ setup guide
  - เพิ่มตาราง secrets แยก UAT/PROD prefix
  - เพิ่ม Deploy Flow diagram
  - ปรับ branch ใน example จาก `main/develop` เป็น `master` ตามจริง
  - ปรับ deploy trigger: UAT = workflow_dispatch, PROD = tag + workflow_dispatch

- **2026-03-12**: Initial release
  - angular-ci.yml / angular-deploy.yml (SSH + Static Files)
  - springboot-ci.yml / springboot-deploy.yml (SSH + WAR/Tomcat)
  - Installer script (install.sh)
  - Example caller workflows
