#!/bin/bash

# 🚀 CI/CD Templates Installer
# ใช้งาน: git clone git@github.com:anon120655/devops.git /tmp/cicd && /tmp/cicd/install.sh <framework> && rm -rf /tmp/cicd

set -e

FRAMEWORK=$1
REPO_URL="git@github.com:anon120655/devops.git"
BRANCH="main"

# ─────────────────────────────────────────────────────────────
# ตรวจสอบ argument
# ─────────────────────────────────────────────────────────────
if [ -z "$FRAMEWORK" ]; then
  echo ""
  echo "🚀 CI/CD Templates Installer (Reusable Workflows)"
  echo "────────────────────────────────────────────────────"
  echo ""
  echo "Usage: /path/to/install.sh <framework>"
  echo ""
  echo "Available frameworks:"
  echo "  ✅ angular       - Angular (SSH + Static Files)"
  echo "  ✅ springboot    - Spring Boot (SSH + WAR/Tomcat)"
  echo ""
  echo "Example:"
  echo "  git clone git@github.com:anon120655/devops.git /tmp/cicd && /tmp/cicd/install.sh angular"
  echo ""
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# ตรวจสอบ framework
# ─────────────────────────────────────────────────────────────
case $FRAMEWORK in
  angular|springboot)
    echo "📦 Installing CI/CD for: $FRAMEWORK"
    ;;
  *)
    echo "❌ Unknown framework: $FRAMEWORK"
    echo "   Available: angular, springboot"
    exit 1
    ;;
esac

# ─────────────────────────────────────────────────────────────
# ตรวจสอบว่ามี .github อยู่แล้วหรือไม่
# ─────────────────────────────────────────────────────────────
if [ -d ".github/workflows" ]; then
  echo ""
  echo "⚠️  Warning: .github/workflows already exists!"
  read -p "   Overwrite? (y/N): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
  fi
fi

# ─────────────────────────────────────────────────────────────
# ติดตั้ง (ใช้ examples folder)
# ─────────────────────────────────────────────────────────────
echo "📥 Downloading templates..."

# ตรวจสอบว่ารันจาก local repo หรือไม่
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/examples/$FRAMEWORK/.github/workflows" ]; then
  # รันจาก local clone - ใช้ไฟล์ที่มีอยู่แล้ว
  echo "📂 Using local templates from: $SCRIPT_DIR/examples/$FRAMEWORK"
  SOURCE_DIR="$SCRIPT_DIR/examples/$FRAMEWORK/.github/workflows"
else
  # Clone จาก remote
  TEMP_DIR=$(mktemp -d)
  trap "rm -rf $TEMP_DIR" EXIT

  cd "$TEMP_DIR"
  git clone --filter=blob:none --sparse --depth 1 -b $BRANCH "$REPO_URL" repo 2>/dev/null
  cd repo
  git sparse-checkout set "examples/$FRAMEWORK" 2>/dev/null
  cd - > /dev/null

  SOURCE_DIR="$TEMP_DIR/repo/examples/$FRAMEWORK/.github/workflows"
fi

# Copy ไปยัง project
mkdir -p .github/workflows
cp -r "$SOURCE_DIR/"* .github/workflows/

# ─────────────────────────────────────────────────────────────
# เสร็จสิ้น
# ─────────────────────────────────────────────────────────────
echo ""
echo "✅ CI/CD for $FRAMEWORK installed successfully!"
echo ""
echo "📁 Files created:"
ls -la .github/workflows/
echo ""
echo "📋 ขั้นตอนต่อไป:"
echo "   1. ✅ Organization ถูกตั้งค่าเป็น anon120655 แล้ว"
echo ""
echo "   2. แก้ไขค่า config ในไฟล์ .github/workflows/deploy.yml"

case $FRAMEWORK in
  angular)
    echo "      🔹 deploy-path               : Path บน server สำหรับวาง static files"
    echo "      🔹 angular-build-configuration : Build config เช่น uat, production"
    echo "      🔹 prebuild-script           : (Optional) Script ก่อน build"
    echo "      🔹 dist-subfolder            : (Optional) ชื่อ subfolder ใน dist/"
    ;;
  springboot)
    echo "      🔹 war-filename         : ชื่อไฟล์ WAR (เช่น app-backend.war)"
    echo "      🔹 tomcat-webapps-path  : Path ของ Tomcat webapps (เช่น /opt/tomcat/webapps)"
    echo "      🔹 deploy-staging-path  : Path สำหรับวาง WAR ชั่วคราว (เช่น /home/locus/deploy)"
    echo "      🔹 tomcat-service-name  : ชื่อ service ของ Tomcat (เช่น tomcat)"
    ;;
esac

echo ""
echo "   3. เพิ่ม GitHub Secrets (ไปที่ Settings > Secrets and variables > Actions)"
echo "      🔹 SSH_HOST        : IP Address หรือ Domain ของ Server"
echo "      🔹 SSH_USERNAME    : Username สำหรับ login เข้า Server"
echo "      🔹 SSH_PRIVATE_KEY : Private Key สำหรับ SSH (ต้องมีบรรทัด BEGIN/END)"
echo "      🔹 SSH_PORT        : (Optional) Port SSH หากไม่ใช่ 22"
echo ""
echo "   4. Push code ขึ้น git และสร้าง Tag เพื่อเริ่มการ Deploy"
echo "      git tag v1.0.0"
echo "      git push origin v1.0.0"
echo ""
echo "✅ Workflows ใช้ Reusable Templates จาก anon120655/devops"
echo "   แก้ไขที่ต้นทางที่เดียว ทุก project อัพเดตตาม!"
