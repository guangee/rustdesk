# 🚀 Windows 测试签名构建 - 快速开始

## ⚡ 3 步完成配置

### 1️⃣ 生成测试证书（在 Windows 上）

```powershell
# 以管理员身份运行 PowerShell
cd /path/to/rustdesk
./res/create-test-certificate.ps1
```

**输出文件：**
- `rustdesk-test-cert.pfx`
- `rustdesk-test-cert-base64.txt` ← 需要复制内容

---

### 2️⃣ 配置 GitHub Secrets

进入：`Settings` → `Secrets and variables` → `Actions`

添加 2 个 secrets：

| Secret 名称 | 值 |
|------------|-----|
| `WINDOWS_CERTIFICATE_BASE64` | 复制 `rustdesk-test-cert-base64.txt` 的内容 |
| `WINDOWS_CERTIFICATE_PASSWORD` | `RustDeskTest2024!` |

---

### 3️⃣ 触发构建

```bash
# 推送代码或创建 tag
git push

# 或手动触发 GitHub Actions workflow
```

---

## ✅ 已完成的配置

- ✅ 禁用了 macOS、iOS、Android、Linux 构建
- ✅ 只构建 Windows x86_64 (64位) 和 x86 (32位)
- ✅ 使用直接签名（不需要远程签名服务器）
- ✅ 自动签名 exe、dll、msi 文件

---

## 📦 构建产物

构建完成后在 GitHub Releases 中获取：

- `rustdesk-1.4.3-x86_64.exe` - 64位自解压安装程序
- `rustdesk-1.4.3-x86_64.msi` - 64位 MSI 安装包
- `rustdesk-1.4.3-x86-sciter.exe` - 32位版本

---

## ⚠️  测试证书警告

使用测试证书时，用户会看到：
- Windows SmartScreen 警告
- "未知发布者"提示
- 需要点击"更多信息" → "仍要运行"

**生产环境请使用正式证书！**

---

## 🔍 验证签名

下载文件后：

**方法 1：**
右键点击 exe → 属性 → 数字签名

**方法 2：**
```powershell
Get-AuthenticodeSignature "rustdesk.exe" | Format-List *
```

---

## 📚 详细文档

- [WINDOWS_ONLY_BUILD_SETUP.md](./WINDOWS_ONLY_BUILD_SETUP.md) - 完整配置指南
- [SIGNING_GUIDE.md](./SIGNING_GUIDE.md) - 签名详解
- [故障排查](./WINDOWS_ONLY_BUILD_SETUP.md#-故障排查)

---

**配置时间：** < 5 分钟  
**状态：** ✅ 可以直接使用

