# Windows 测试签名构建配置指南

本指南将帮助您配置仅构建 Windows 应用，并使用测试证书进行签名。

## 📋 配置清单

- ✅ 已禁用 macOS 构建
- ✅ 已禁用 iOS 构建  
- ✅ 已禁用 Android 构建
- ✅ 已禁用 Linux 构建
- ✅ 已配置 Windows 直接签名（不再使用远程签名服务器）
- ✅ 创建了自签名证书生成脚本
- ✅ 创建了 Windows 签名脚本

## 🚀 快速开始

### 第一步：生成测试证书

在 **Windows 机器上**运行 PowerShell（以管理员身份）：

```powershell
# 进入项目目录
cd /path/to/rustdesk

# 运行证书生成脚本
./res/create-test-certificate.ps1
```

脚本会生成以下文件：
- `rustdesk-test-cert.pfx` - 证书文件
- `rustdesk-test-cert-base64.txt` - Base64 编码的证书（用于 GitHub Secrets）

**重要信息：**
- 证书密码：`RustDeskTest2024!`
- 证书有效期：5 年

### 第二步：配置 GitHub Secrets

1. 打开您的 GitHub 仓库
2. 进入 `Settings` → `Secrets and variables` → `Actions`
3. 点击 `New repository secret`
4. 添加以下两个 secrets：

#### Secret 1: WINDOWS_CERTIFICATE_BASE64

- **名称**：`WINDOWS_CERTIFICATE_BASE64`
- **值**：复制 `rustdesk-test-cert-base64.txt` 文件的全部内容

#### Secret 2: WINDOWS_CERTIFICATE_PASSWORD

- **名称**：`WINDOWS_CERTIFICATE_PASSWORD`  
- **值**：`RustDeskTest2024!`

### 第三步：触发构建

1. 提交并推送代码到 GitHub
2. 创建一个 tag 触发构建，或者手动触发 workflow
3. 等待构建完成

## 📦 构建产物

构建成功后，您将在 GitHub Releases 中找到以下文件：

### Windows 64位 Flutter 版本
- `rustdesk-1.4.3-x86_64.exe` - 自解压安装程序（已签名）
- `rustdesk-1.4.3-x86_64.msi` - MSI 安装包（已签名）

### Windows 32位 Sciter 版本（可选）
- `rustdesk-1.4.3-x86-sciter.exe` - 自解压安装程序（已签名）

## ⚠️  重要提示

### 测试证书的限制

使用自签名测试证书时，用户会看到以下警告：

1. **Windows SmartScreen**：
   ```
   Windows 已保护你的电脑
   Microsoft Defender SmartScreen 阻止了未识别的应用启动
   ```
   用户需要点击"更多信息" → "仍要运行"

2. **代码签名警告**：
   ```
   未知发布者
   此应用可能会损害你的设备
   ```

3. **用户体验影响**：
   - 用户需要额外步骤才能运行应用
   - 可能降低用户信任度
   - 不适合正式发布

### 推荐用于生产环境的方案

对于正式发布，强烈建议：

1. **购买正式的代码签名证书**
   - 标准证书：$200-400/年
   - EV 证书：$400-600/年（立即受信任，无 SmartScreen 警告）

2. **推荐的证书提供商**：
   - DigiCert：https://www.digicert.com/code-signing
   - Sectigo：https://sectigo.com/ssl-certificates-tls/code-signing
   - SSL.com：https://www.ssl.com/certificates/code-signing/

3. **配置正式证书**：
   - 将正式证书的 PFX 转换为 Base64
   - 更新 `WINDOWS_CERTIFICATE_BASE64` secret
   - 更新 `WINDOWS_CERTIFICATE_PASSWORD` secret

## 🔧 本地测试签名

如果您想在本地测试签名流程：

```powershell
# 1. 设置环境变量
$env:WINDOWS_CERTIFICATE_BASE64 = (Get-Content rustdesk-test-cert-base64.txt -Raw)
$env:WINDOWS_CERTIFICATE_PASSWORD = "RustDeskTest2024!"

# 2. 构建应用（假设已构建完成）
# python build.py --flutter ...

# 3. 运行签名脚本
./res/sign-windows.ps1 -FilePath "./flutter/build/windows/x64/runner/Release"

# 4. 验证签名
Get-AuthenticodeSignature "./flutter/build/windows/x64/runner/Release/rustdesk.exe" | Format-List *
```

## 📊 工作流更改摘要

已做出以下更改：

### 1. 禁用的构建平台

```yaml
build-for-macOS:        if: false  # 禁用
build-rustdesk-ios:     if: false  # 禁用
build-rustdesk-android: if: false  # 禁用
build-rustdesk-linux:   if: false  # 禁用
build-appimage:         if: false  # 禁用
build-flatpak:          if: false  # 禁用
```

### 2. 签名方式更改

**之前**（远程签名服务器）：
```yaml
- name: Sign rustdesk files
  if: env.UPLOAD_ARTIFACT == 'true' && env.SIGN_BASE_URL != ''
  run: |
    BASE_URL=${{ secrets.SIGN_BASE_URL }} python3 res/job.py sign_files ./rustdesk/
```

**现在**（直接签名）：
```yaml
- name: Sign rustdesk files
  if: env.UPLOAD_ARTIFACT == 'true'
  shell: powershell
  run: |
    if ("${{ secrets.WINDOWS_CERTIFICATE_BASE64 }}" -eq "") {
      Write-Host "⚠️  未配置 Windows 证书，跳过签名"
      exit 0
    }
    ./res/sign-windows.ps1 -FilePath "./rustdesk"
  env:
    WINDOWS_CERTIFICATE_BASE64: ${{ secrets.WINDOWS_CERTIFICATE_BASE64 }}
    WINDOWS_CERTIFICATE_PASSWORD: ${{ secrets.WINDOWS_CERTIFICATE_PASSWORD }}
```

### 3. 新增的脚本

- `res/create-test-certificate.ps1` - 生成自签名测试证书
- `res/sign-windows.ps1` - Windows 代码签名工具

## 🐛 故障排查

### 问题：证书生成失败

**错误**：`New-SelfSignedCertificate: 拒绝访问`

**解决**：以管理员身份运行 PowerShell

---

### 问题：签名失败 - signtool 找不到

**错误**：`未找到 signtool.exe`

**解决**：GitHub Actions 环境已包含 Windows SDK，本地测试需要安装：
- 下载 Windows SDK：https://developer.microsoft.com/windows/downloads/windows-sdk/
- 或安装 Visual Studio（包含 Windows SDK）

---

### 问题：时间戳服务器超时

**错误**：`The specified timestamp server either could not be reached`

**解决**：签名脚本会自动尝试多个时间戳服务器，通常会自动恢复。如果持续失败，可能是网络问题。

---

### 问题：GitHub Actions 中签名步骤被跳过

**原因**：未配置 `WINDOWS_CERTIFICATE_BASE64` secret

**解决**：按照"第二步：配置 GitHub Secrets"添加所需的 secrets

---

### 问题：构建的应用仍显示"未签名"

**检查**：
1. 查看 GitHub Actions 日志，确认签名步骤成功执行
2. 下载构建产物后，右键点击 exe → 属性 → 数字签名，查看是否有签名信息
3. 运行 PowerShell 命令验证：
   ```powershell
   Get-AuthenticodeSignature "rustdesk.exe" | Format-List *
   ```

## 📚 相关文档

- [SIGNING_GUIDE.md](./SIGNING_GUIDE.md) - 完整的签名配置指南
- [SIGNING_WORKFLOW_CHANGES.md](./SIGNING_WORKFLOW_CHANGES.md) - 工作流修改详解
- [QUICK_SIGNING_SETUP.md](./QUICK_SIGNING_SETUP.md) - 快速参考指南

## 🎯 下一步

完成测试签名配置后：

1. ✅ 验证构建和签名流程正常工作
2. ✅ 在本地测试下载的应用
3. ✅ 确认所有功能正常
4. 🔜 考虑购买正式的代码签名证书用于生产环境

## 💬 需要帮助？

如果遇到问题：

1. 查看 GitHub Actions 日志中的详细错误信息
2. 检查本文档的"故障排查"部分
3. 查阅相关文档了解更多细节
4. 提交 Issue 获取支持

---

**最后更新：** 2025-10-25
**配置状态：** ✅ 已完成

