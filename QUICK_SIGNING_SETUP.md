# 快速签名配置指南

## 📋 配置清单

### Windows 签名

| 步骤 | 操作 | 完成 |
|------|------|------|
| 1️⃣ | 购买或创建代码签名证书 | ☐ |
| 2️⃣ | 导出证书为 PFX 格式 | ☐ |
| 3️⃣ | 转换 PFX 为 Base64 | ☐ |
| 4️⃣ | 配置 GitHub Secret: `WINDOWS_CERTIFICATE_BASE64` | ☐ |
| 5️⃣ | 配置 GitHub Secret: `WINDOWS_CERTIFICATE_PASSWORD` | ☐ |
| 6️⃣ | 修改工作流文件 | ☐ |

### macOS 签名和公证

| 步骤 | 操作 | 完成 |
|------|------|------|
| 1️⃣ | 加入 Apple Developer Program ($99/年) | ☐ |
| 2️⃣ | 创建 Developer ID Application 证书 | ☐ |
| 3️⃣ | 导出证书为 P12 格式 | ☐ |
| 4️⃣ | 转换 P12 为 Base64 | ☐ |
| 5️⃣ | 创建 App Store Connect API 密钥 | ☐ |
| 6️⃣ | 创建公证配置 JSON 文件 | ☐ |
| 7️⃣ | 转换 JSON 为 Base64 | ☐ |
| 8️⃣ | 配置 GitHub Secret: `MACOS_P12_BASE64` | ☐ |
| 9️⃣ | 配置 GitHub Secret: `MACOS_P12_PASSWORD` | ☐ |
| 🔟 | 配置 GitHub Secret: `MACOS_CODESIGN_IDENTITY` | ☐ |
| 1️⃣1️⃣ | 配置 GitHub Secret: `MACOS_NOTARIZE_JSON` | ☐ |

---

## 🚀 快速命令

### Windows - 转换 PFX 到 Base64

**PowerShell:**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.pfx")) | Out-File certificate-base64.txt
```

**Linux/macOS:**
```bash
base64 -i certificate.pfx -o certificate-base64.txt
```

### macOS - 转换 P12 到 Base64

```bash
base64 -i certificate.p12 -o certificate-base64.txt
```

### macOS - 获取代码签名身份

```bash
security find-identity -v -p codesigning
```

输出示例：
```
1) ABC123XYZ "Developer ID Application: Your Name (TEAM_ID)"
```

复制引号中的完整字符串：`Developer ID Application: Your Name (TEAM_ID)`

### macOS - 创建公证配置 JSON

```json
{
  "api_key_id": "YOUR_KEY_ID",
  "api_key_issuer_id": "YOUR_ISSUER_ID",
  "api_key": "-----BEGIN PRIVATE KEY-----\nYOUR_P8_KEY_CONTENT_HERE\n-----END PRIVATE KEY-----"
}
```

保存为 `notarize.json`，然后：
```bash
base64 -i notarize.json -o notarize-base64.txt
```

---

## 🔐 GitHub Secrets 配置

进入仓库设置：`Settings` → `Secrets and variables` → `Actions` → `New repository secret`

### 需要配置的 Secrets

| Secret 名称 | 用途 | 如何获取 |
|------------|------|---------|
| `WINDOWS_CERTIFICATE_BASE64` | Windows 代码签名 | PFX 文件的 Base64 编码 |
| `WINDOWS_CERTIFICATE_PASSWORD` | Windows 证书密码 | 导出 PFX 时设置的密码 |
| `MACOS_P12_BASE64` | macOS 代码签名 | P12 文件的 Base64 编码 |
| `MACOS_P12_PASSWORD` | macOS 证书密码 | 导出 P12 时设置的密码 |
| `MACOS_CODESIGN_IDENTITY` | macOS 签名身份 | 运行 `security find-identity` 获取 |
| `MACOS_NOTARIZE_JSON` | macOS 公证配置 | 公证 JSON 的 Base64 编码 |

---

## 💰 费用估算

### Windows 代码签名证书

| 提供商 | 证书类型 | 价格/年 | 特点 |
|--------|---------|---------|------|
| DigiCert | 标准 | ~$474 | 行业标准 |
| DigiCert | EV | ~$595 | 立即受信任 |
| Sectigo | 标准 | ~$200-400 | 性价比高 |
| SSL.com | 标准 | ~$200 | 经济实惠 |

### macOS

| 项目 | 价格 |
|------|------|
| Apple Developer Program | $99/年 |

**总计：**
- **Windows 签名**：$200-600/年
- **macOS 签名**：$99/年
- **两者都需要**：约 $300-700/年

---

## ⚡ 最简单的测试方案

### 如果您只想快速测试（不推荐用于生产）

#### Windows - 自签名证书

```powershell
# 创建自签名证书
$cert = New-SelfSignedCertificate -Type CodeSigningCert `
  -Subject "CN=TestCompany, O=Test, C=US" `
  -CertStoreLocation Cert:\CurrentUser\My `
  -NotAfter (Get-Date).AddYears(5)

# 导出为 PFX
$password = ConvertTo-SecureString -String "YourPassword123" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "test-cert.pfx" -Password $password

# 转换为 Base64
[Convert]::ToBase64String([IO.File]::ReadAllBytes("test-cert.pfx")) | Out-File test-cert-base64.txt
```

**注意：** 自签名证书用户仍会看到安全警告！

---

## 🐛 常见问题速查

### Windows

| 问题 | 原因 | 解决方法 |
|------|------|---------|
| SmartScreen 警告 | 新证书或自签名 | 使用 EV 证书或积累信誉 |
| 签名验证失败 | 证书配置错误 | 检查 Base64 和密码是否正确 |
| signtool 找不到 | 未安装 Windows SDK | GitHub Actions 自带，无需处理 |

### macOS

| 问题 | 原因 | 解决方法 |
|------|------|---------|
| "已损坏" 提示 | 未签名或公证失败 | 检查证书和 API 密钥配置 |
| Gatekeeper 阻止 | 未公证 | 确保公证步骤成功 |
| 公证超时 | Apple 服务器繁忙 | 增加超时时间或重试 |

---

## 📚 相关文档

- 详细指南：[SIGNING_GUIDE.md](./SIGNING_GUIDE.md)
- 工作流修改：[SIGNING_WORKFLOW_CHANGES.md](./SIGNING_WORKFLOW_CHANGES.md)
- GitHub Actions 工作流：[.github/workflows/flutter-build.yml](./.github/workflows/flutter-build.yml)

---

## ✅ 验证签名

### Windows

```powershell
# 方法 1：使用 signtool
signtool verify /pa /v rustdesk.exe

# 方法 2：右键属性
# 右键点击 exe → 属性 → 数字签名
```

### macOS

```bash
# 验证签名
codesign -vvv --deep --strict RustDesk.app

# 验证公证
spctl -a -vvv RustDesk.app

# 检查公证票据
stapler validate RustDesk.dmg
```

---

## 🎯 推荐流程

### 第一次配置（测试）

1. ✅ 使用自签名证书测试 Windows 签名流程
2. ✅ 验证工作流是否正常运行
3. ✅ 确认签名步骤无报错

### 正式部署

1. ✅ 购买正式的代码签名证书
2. ✅ 申请 Apple Developer Program
3. ✅ 配置所有 GitHub Secrets
4. ✅ 运行完整构建并测试下载的应用

### 维护

- 📅 证书到期前 30 天续费
- 🔒 定期轮换 API 密钥
- 📊 监控签名失败率

---

## 需要帮助？

如果遇到问题：

1. 📖 查看 [SIGNING_GUIDE.md](./SIGNING_GUIDE.md) 详细指南
2. 🔍 检查 GitHub Actions 日志
3. 🐛 搜索错误信息
4. 💬 提交 Issue 获取支持

---

**最后更新：** 2025-10-25

