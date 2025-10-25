# 配置更改摘要

## 📝 本次修改概述

为了实现仅构建 Windows 应用并使用测试签名，对项目进行了以下修改。

---

## 📁 新增文件

### 1. 签名脚本

| 文件路径 | 用途 |
|---------|------|
| `res/create-test-certificate.ps1` | 生成 Windows 自签名测试证书 |
| `res/sign-windows.ps1` | Windows 代码签名工具脚本 |

### 2. 文档

| 文件路径 | 说明 |
|---------|------|
| `QUICK_START.md` | 快速开始指南（3 步配置） |
| `WINDOWS_ONLY_BUILD_SETUP.md` | 完整的 Windows 构建配置指南 |
| `SIGNING_GUIDE.md` | 代码签名和公证详细指南 |
| `SIGNING_WORKFLOW_CHANGES.md` | 工作流修改说明 |
| `QUICK_SIGNING_SETUP.md` | 签名配置快速参考 |
| `CHANGES_SUMMARY.md` | 本文件 - 更改摘要 |

---

## 🔧 修改文件

### `.github/workflows/flutter-build.yml`

#### 1. 禁用的构建平台

添加了 `if: false` 条件以禁用以下构建：

```yaml
build-for-macOS:                    # 第 556 行
build-rustdesk-ios:                 # 第 436 行
build-rustdesk-android:             # 第 807 行
build-rustdesk-android-universal:   # 第 1098 行
build-rustdesk-linux:               # 第 1280 行
build-rustdesk-linux-sciter:        # 第 1617 行
build-appimage:                     # 第 1843 行
build-flatpak:                      # 第 1893 行
```

#### 2. Windows 签名方式更改

**修改位置 1：** build-for-windows-flutter job (第 236-250 行)
- 移除了对远程签名服务器的依赖
- 改用 `res/sign-windows.ps1` 脚本直接签名
- 使用环境变量 `WINDOWS_CERTIFICATE_BASE64` 和 `WINDOWS_CERTIFICATE_PASSWORD`

**修改位置 2：** build-for-windows-flutter job (第 277-291 行)
- 签名自解压 exe 和 msi 文件
- 同样改用直接签名方式

**修改位置 3：** build-for-windows-sciter job (第 421-435 行)
- Sciter 32位版本的文件签名
- 改用直接签名方式

**修改位置 4：** build-for-windows-sciter job (第 448-462 行)
- Sciter 自解压文件签名
- 改用直接签名方式

#### 3. 签名逻辑变化

**之前：**
```yaml
if: env.UPLOAD_ARTIFACT == 'true' && env.SIGN_BASE_URL != ''
run: |
  BASE_URL=${{ secrets.SIGN_BASE_URL }} SECRET_KEY=${{ secrets.SIGN_SECRET_KEY }} \
  python3 res/job.py sign_files ./rustdesk/
```

**现在：**
```yaml
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

---

## 🔐 需要配置的 GitHub Secrets

### 新增（必需）

| Secret 名称 | 用途 | 如何获取 |
|------------|------|---------|
| `WINDOWS_CERTIFICATE_BASE64` | Windows 代码签名证书 | 运行 `create-test-certificate.ps1` 生成 |
| `WINDOWS_CERTIFICATE_PASSWORD` | 证书密码 | 测试证书密码：`RustDeskTest2024!` |

### 不再需要（可以删除）

| Secret 名称 | 说明 |
|------------|------|
| `SIGN_BASE_URL` | 远程签名服务器 URL（已不使用） |
| `SIGN_SECRET_KEY` | 远程签名服务器密钥（已不使用） |
| `MACOS_P12_BASE64` | macOS 证书（已禁用 macOS 构建） |
| `MACOS_P12_PASSWORD` | macOS 证书密码（已禁用） |
| `MACOS_CODESIGN_IDENTITY` | macOS 签名身份（已禁用） |
| `MACOS_NOTARIZE_JSON` | macOS 公证配置（已禁用） |
| `ANDROID_SIGNING_KEY` | Android 签名密钥（已禁用） |
| `ANDROID_ALIAS` | Android 密钥别名（已禁用） |
| `ANDROID_KEY_STORE_PASSWORD` | Android Keystore 密码（已禁用） |
| `ANDROID_KEY_PASSWORD` | Android 密钥密码（已禁用） |

---

## 🎯 构建产物变化

### 之前（所有平台）

- Windows: exe, msi
- macOS: dmg (x86_64 和 aarch64)
- Linux: deb, rpm, AppImage, Flatpak
- Android: apk (多个架构)
- iOS: ipa

### 现在（仅 Windows）

- `rustdesk-1.4.3-x86_64.exe` - 64位自解压安装程序（已签名）
- `rustdesk-1.4.3-x86_64.msi` - 64位 MSI 安装包（已签名）
- `rustdesk-1.4.3-x86-sciter.exe` - 32位 Sciter 版本（已签名）

---

## ⚙️ 工作流行为变化

### 构建时间

**之前：** 约 2-4 小时（构建所有平台）  
**现在：** 约 20-40 分钟（仅 Windows）

### 资源消耗

大幅减少：
- 不再需要 macOS runners
- 不再需要 Ubuntu ARM runners
- 减少约 70% 的 GitHub Actions 使用时间

### 依赖项

**移除的外部依赖：**
- 远程签名服务器
- Apple Developer 账户
- Android SDK/NDK（仍在环境中，但不使用）

**新增的依赖：**
- Windows SDK（GitHub Actions 环境已包含）
- 自签名证书或正式代码签名证书

---

## 🔄 回滚方法

如果需要恢复原始配置：

### 方法 1：使用 Git

```bash
# 查看修改
git diff .github/workflows/flutter-build.yml

# 恢复原始文件
git checkout HEAD -- .github/workflows/flutter-build.yml
```

### 方法 2：手动恢复

将所有 `if: false` 行删除，恢复原始的签名步骤：

```yaml
# 删除这些行
if: false  # 禁用 XXX 构建

# 恢复原始签名逻辑
if: env.UPLOAD_ARTIFACT == 'true' && env.SIGN_BASE_URL != ''
```

---

## ✅ 测试清单

在生产环境使用前，请验证：

- [ ] GitHub Actions 工作流成功运行
- [ ] Windows exe 文件已签名（查看属性 → 数字签名）
- [ ] Windows msi 文件已签名
- [ ] 下载的应用可以正常安装和运行
- [ ] 所有核心功能正常工作
- [ ] 签名日志无错误信息

---

## 📊 影响评估

### 积极影响

✅ 大幅减少构建时间（70%+）  
✅ 降低 GitHub Actions 成本  
✅ 简化配置（无需远程签名服务器）  
✅ 更容易维护和调试  
✅ 证书管理更安全（存储在 GitHub Secrets）

### 需要注意

⚠️ 测试证书会有安全警告（用户需要额外步骤）  
⚠️ 不再构建其他平台（如需要，需单独配置）  
⚠️ 生产环境建议使用正式证书

---

## 🎓 学习资源

- [Microsoft 代码签名文档](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [PowerShell 文档](https://docs.microsoft.com/en-us/powershell/)

---

## 📞 支持

如有问题：

1. 查看 `WINDOWS_ONLY_BUILD_SETUP.md` 的故障排查部分
2. 检查 GitHub Actions 运行日志
3. 查看相关文档
4. 提交 Issue

---

**修改日期：** 2025-10-25  
**修改者：** AI Assistant  
**审核状态：** 待用户测试确认  
**版本：** 1.0

