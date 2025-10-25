# RustDesk 代码签名和公证配置指南

本指南将帮助您为 Windows 和 macOS 平台配置代码签名和公证。

## Windows 代码签名配置

### 一、获取代码签名证书

#### 选项 1：购买 EV 或标准代码签名证书（推荐）

**推荐的证书颁发机构：**
- **DigiCert**：https://www.digicert.com/code-signing - 约 $474/年
- **Sectigo (Comodo)**：https://sectigo.com/ssl-certificates-tls/code-signing - 约 $200-400/年
- **GlobalSign**：约 $300/年
- **SSL.com**：约 $200/年

**证书类型：**
- **标准代码签名证书**：价格较低，但新证书需要建立信誉（SmartScreen 可能仍会警告）
- **EV 代码签名证书**：价格较高，但立即受信任，不会触发 SmartScreen

#### 选项 2：自签名证书（仅用于开发测试）

```powershell
# 创建自签名证书（用户仍会看到警告）
New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=YourCompany, O=YourOrganization, C=US" `
  -CertStoreLocation Cert:\CurrentUser\My `
  -NotAfter (Get-Date).AddYears(5)
```

### 二、导出证书

1. **打开证书管理器**：
   ```powershell
   certmgr.msc
   ```

2. **导出证书**：
   - 找到您的证书（通常在"个人" -> "证书"）
   - 右键点击证书 -> "所有任务" -> "导出"
   - 选择"是，导出私钥"
   - 选择"个人信息交换 - PKCS #12 (.PFX)"
   - 勾选"包括证书路径中的所有证书"
   - 设置一个强密码
   - 保存为 `windows-certificate.pfx`

3. **转换为 Base64**：
   ```bash
   # Linux/macOS
   base64 -i windows-certificate.pfx -o windows-certificate-base64.txt
   
   # Windows PowerShell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("windows-certificate.pfx")) | Out-File -FilePath windows-certificate-base64.txt
   ```

### 三、配置 GitHub Secrets

在您的 GitHub 仓库中：

1. 进入 **Settings** -> **Secrets and variables** -> **Actions**
2. 点击 **New repository secret**
3. 添加以下 secrets：

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `WINDOWS_CERTIFICATE_BASE64` | (Base64 编码的 PFX 内容) | Windows 代码签名证书 |
| `WINDOWS_CERTIFICATE_PASSWORD` | (证书密码) | PFX 文件的密码 |

---

## macOS 代码签名和公证配置

### 一、加入 Apple Developer Program

1. 访问 https://developer.apple.com/programs/
2. 注册并支付年费（$99/年，个人或公司账户）

### 二、创建证书

1. **登录 Apple Developer 网站**：
   - 访问 https://developer.apple.com/account/
   
2. **创建 Developer ID Application 证书**：
   - 进入 **Certificates, Identifiers & Profiles**
   - 点击 **Certificates** -> **+** (创建新证书)
   - 选择 **Developer ID Application**（用于在 Mac App Store 外分发）
   - 按照指示创建 CSR（证书签名请求）
   - 下载证书并双击安装到钥匙串

3. **导出证书为 P12 格式**：
   - 打开"钥匙串访问"（Keychain Access）
   - 找到您的 Developer ID Application 证书
   - 右键点击 -> "导出"
   - 保存为 `.p12` 格式
   - 设置一个强密码

4. **转换为 Base64**：
   ```bash
   base64 -i certificate.p12 -o certificate-base64.txt
   ```

### 三、创建 App Store Connect API 密钥（用于公证）

1. **登录 App Store Connect**：
   - 访问 https://appstoreconnect.apple.com/
   
2. **创建 API 密钥**：
   - 进入 **用户和访问** -> **密钥**
   - 点击 **+** 创建新密钥
   - 名称：RustDesk Notarization
   - 访问权限：**Developer**
   - 下载密钥文件（.p8 格式）
   - **记录 Issuer ID 和 Key ID**

3. **创建公证配置文件**：
   
   创建一个 JSON 文件 `notarize-config.json`：
   ```json
   {
     "api_key_id": "YOUR_KEY_ID",
     "api_key_issuer_id": "YOUR_ISSUER_ID",
     "api_key": "-----BEGIN PRIVATE KEY-----\nYOUR_P8_KEY_CONTENT\n-----END PRIVATE KEY-----"
   }
   ```
   
   将 P8 文件内容复制到 `api_key` 字段，保持换行符为 `\n`。

4. **转换为 Base64**：
   ```bash
   base64 -i notarize-config.json -o notarize-config-base64.txt
   ```

### 四、获取代码签名身份标识

在 macOS 终端运行：
```bash
security find-identity -v -p codesigning
```

找到类似这样的输出：
```
1) XXXXXXXXXX "Developer ID Application: Your Name (TEAM_ID)"
```

记录引号中的完整字符串，例如：`Developer ID Application: Your Name (TEAM_ID)`

### 五、配置 GitHub Secrets

在您的 GitHub 仓库中添加以下 secrets：

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `MACOS_P12_BASE64` | (Base64 编码的 P12 内容) | macOS 代码签名证书 |
| `MACOS_P12_PASSWORD` | (P12 文件密码) | 证书导出时设置的密码 |
| `MACOS_CODESIGN_IDENTITY` | `Developer ID Application: Your Name (TEAM_ID)` | 代码签名身份 |
| `MACOS_NOTARIZE_JSON` | (Base64 编码的公证配置 JSON) | App Store Connect API 配置 |

---

## 验证配置

### Windows 验证

签名后，在 Windows 上右键点击 `.exe` 或 `.msi` 文件，选择"属性" -> "数字签名"标签，应该能看到您的签名信息。

### macOS 验证

签名和公证后，运行：
```bash
# 验证签名
codesign -vvv --deep --strict RustDesk.app

# 验证公证
spctl -a -vvv RustDesk.app

# 检查公证状态
stapler validate RustDesk.dmg
```

---

## 常见问题

### Q: 我必须购买证书吗？
**A:** 
- **Windows**：如果您想让用户无警告地安装，是的。自签名证书用户仍会看到"未知发布者"警告。
- **macOS**：是的，必须加入 Apple Developer Program ($99/年) 并使用官方证书，否则用户无法在较新的 macOS 版本上运行。

### Q: EV 证书和标准证书的区别？
**A:** 
- **EV (Extended Validation) 证书**：价格更高，但立即受 Windows SmartScreen 信任
- **标准证书**：价格较低，但需要积累信誉（数周到数月），期间可能仍有 SmartScreen 警告

### Q: 如何测试签名流程？
**A:** 
- 可以先使用自签名证书在本地测试流程
- 确认流程正常后，再购买正式证书

### Q: 证书会过期吗？
**A:** 
- 是的，通常 1-3 年
- 过期前需要续费或购买新证书
- 已签名的文件在证书过期后可能会失去信任

---

## 下一步

配置完成后，您需要修改 `.github/workflows/flutter-build.yml` 文件以使用这些证书进行签名。

请参考项目中的 `SIGNING_WORKFLOW_CHANGES.md` 文件了解如何修改工作流。

