# 生成自签名证书 - 操作指南

## 🖥️ 在 Windows 机器上执行

### 第一步：准备工作

1. 将项目复制到 Windows 机器，或者直接从 GitHub clone
2. 打开 PowerShell **（以管理员身份运行）**
   - 按 `Win + X`
   - 选择"Windows PowerShell (管理员)"或"终端 (管理员)"

### 第二步：执行脚本

```powershell
# 进入项目目录
cd C:\path\to\rustdesk

# 如果遇到执行策略限制，运行：
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# 生成证书
./res/create-test-certificate.ps1
```

### 第三步：查看生成的文件

脚本会在当前目录生成两个文件：

```
✅ rustdesk-test-cert.pfx           ← 证书文件（不要上传到 GitHub）
✅ rustdesk-test-cert-base64.txt    ← 用于 GitHub Secrets
```

### 第四步：复制 Base64 内容

打开 `rustdesk-test-cert-base64.txt`，复制**全部内容**（Ctrl+A, Ctrl+C）

### 第五步：配置 GitHub Secrets

1. 打开您的 GitHub 仓库
2. 进入 `Settings` → `Secrets and variables` → `Actions`
3. 点击 `New repository secret`

#### 添加 Secret 1:
- **Name:** `WINDOWS_CERTIFICATE_BASE64`
- **Value:** 粘贴刚才复制的内容

#### 添加 Secret 2:
- **Name:** `WINDOWS_CERTIFICATE_PASSWORD`
- **Value:** `RustDeskTest2024!`

### 完成！

现在您可以：
```bash
git push
```

GitHub Actions 会自动使用证书签名您的 Windows 应用。

---

## ⚠️ 安全提示

**不要将以下文件提交到 Git：**
- ❌ `rustdesk-test-cert.pfx`
- ❌ `rustdesk-test-cert-base64.txt`

这些文件包含私钥，应该保密！

建议添加到 `.gitignore`：
```
rustdesk-test-cert.pfx
rustdesk-test-cert-base64.txt
*.pfx
*-base64.txt
```

---

## 🔍 验证证书

生成后，可以验证证书：

```powershell
# 查看证书信息
Get-PfxCertificate -FilePath rustdesk-test-cert.pfx

# 导入到证书存储（可选，用于测试）
$password = ConvertTo-SecureString "RustDeskTest2024!" -AsPlainText -Force
Import-PfxCertificate -FilePath rustdesk-test-cert.pfx -CertStoreLocation Cert:\CurrentUser\My -Password $password

# 查看已安装的证书
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
```

---

## 📋 完整命令清单（复制粘贴版）

```powershell
# 1. 以管理员身份打开 PowerShell

# 2. 进入项目目录
cd C:\path\to\rustdesk

# 3. 允许执行脚本（如果需要）
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# 4. 生成证书
./res/create-test-certificate.ps1

# 5. 查看生成的文件
dir rustdesk-test-cert*

# 6. 打开 Base64 文件
notepad rustdesk-test-cert-base64.txt

# 7. 复制全部内容，然后去 GitHub 配置 Secrets
```

---

## 🐛 常见问题

### Q: 提示"无法加载文件，因为在此系统上禁止运行脚本"

**A:** 运行以下命令允许脚本执行：
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Q: 提示"拒绝访问"

**A:** 确保以管理员身份运行 PowerShell

### Q: 证书生成失败

**A:** 查看错误信息，可能需要：
- 确认以管理员身份运行
- 确认 PowerShell 版本 >= 5.1
- 运行 `Get-Host` 查看版本

### Q: Base64 文件很长，全部复制吗？

**A:** 是的！全部复制，包括开头和结尾的所有字符

---

## 📊 预期输出

脚本成功运行后应该看到：

```
========================================
  RustDesk 测试签名证书生成工具
========================================

[1/4] 创建自签名证书...
✅ 证书创建成功
   Thumbprint: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

[2/4] 导出证书为 PFX 格式...
✅ PFX 导出成功: rustdesk-test-cert.pfx

[3/4] 转换为 Base64 编码...
✅ Base64 编码成功: rustdesk-test-cert-base64.txt

[4/4] 生成配置摘要...

========================================
  证书配置信息
========================================

📁 生成的文件:
   • rustdesk-test-cert.pfx
   • rustdesk-test-cert-base64.txt

🔐 GitHub Secrets 配置:

   Secret 名称: WINDOWS_CERTIFICATE_BASE64
   Secret 值: (请复制 rustdesk-test-cert-base64.txt 的内容)

   Secret 名称: WINDOWS_CERTIFICATE_PASSWORD
   Secret 值: RustDeskTest2024!

⚠️  重要提示:
   • 这是测试证书，用户仍会看到安全警告
   • 生产环境请使用正式的代码签名证书
   • 证书密码: RustDeskTest2024!

========================================
✅ 证书生成完成！
========================================
```

---

**下一步：** 配置完 GitHub Secrets 后，推送代码触发构建！

