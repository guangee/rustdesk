# 🔐 生成自签名证书 - 完整指南

由于您在 macOS 上，我为您提供了**两种方法**生成 Windows 自签名证书。

---

## 🚀 方法一：使用 GitHub Actions 自动生成（推荐！最简单）

### 优势
✅ 无需 Windows 机器  
✅ 全自动化，一键生成  
✅ 安全，证书不会泄露  
✅ 适合 macOS/Linux 用户  

### 操作步骤

#### 第一步：推送工作流文件

```bash
cd /Volumes/ExtendedSpace/Projects/IdeaProjects/rustdesk

# 提交新创建的工作流
git add .github/workflows/generate-test-certificate.yml
git commit -m "添加自动生成测试证书工作流"
git push
```

#### 第二步：在 GitHub 上手动触发工作流

1. 打开您的 GitHub 仓库页面
2. 点击顶部的 `Actions` 标签
3. 在左侧找到 `Generate Test Certificate`
4. 点击右侧的 `Run workflow` 下拉按钮
5. 点击绿色的 `Run workflow` 按钮

![GitHub Actions Manual Trigger](https://docs.github.com/assets/cb-33892/mw-1440/images/help/actions/workflow-dispatch-button.webp)

#### 第三步：等待工作流完成（约 1-2 分钟）

工作流会：
- ✅ 创建自签名证书
- ✅ 导出为 PFX 格式
- ✅ 转换为 Base64
- ✅ 上传为 Artifact

#### 第四步：下载证书文件

1. 工作流完成后，向下滚动到页面底部
2. 在 `Artifacts` 部分找到 `test-certificate`
3. 点击下载（会下载一个 zip 文件）
4. 解压 zip 文件，得到 `rustdesk-test-cert-base64.txt`

#### 第五步：配置 GitHub Secrets

1. 在仓库中进入 `Settings` → `Secrets and variables` → `Actions`
2. 点击 `New repository secret`

**添加 Secret 1:**
```
Name:  WINDOWS_CERTIFICATE_BASE64
Value: (打开 rustdesk-test-cert-base64.txt，复制全部内容并粘贴)
```

**添加 Secret 2:**
```
Name:  WINDOWS_CERTIFICATE_PASSWORD
Value: RustDeskTest2024!
```

#### 第六步：触发构建

```bash
# 随便做个小改动触发构建，或者直接推送
git commit --allow-empty -m "触发签名构建"
git push
```

#### ✅ 完成！

现在您的 Windows 应用会自动签名！

---

## 🖥️ 方法二：在 Windows 机器上手动生成

如果您有 Windows 机器访问权限（物理机、虚拟机、远程桌面等）：

### 第一步：复制项目到 Windows

通过以下任一方式：
- Git clone 到 Windows 机器
- 通过网络共享复制项目文件夹
- 使用 USB 驱动器传输

### 第二步：运行生成脚本

```powershell
# 以管理员身份打开 PowerShell
# 右键点击"开始"按钮 -> Windows PowerShell (管理员)

# 进入项目目录
cd C:\path\to\rustdesk

# 如果遇到执行策略限制
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# 运行脚本
./res/create-test-certificate.ps1
```

### 第三步：获取生成的文件

脚本会在当前目录生成：
- `rustdesk-test-cert.pfx` - 证书文件（保密！）
- `rustdesk-test-cert-base64.txt` - 用于 GitHub Secrets

### 第四步：配置 GitHub Secrets

同方法一的第五步。

---

## 📊 两种方法对比

| 特性 | 方法一 (GitHub Actions) | 方法二 (手动) |
|------|------------------------|--------------|
| **需要 Windows** | ❌ 不需要 | ✅ 需要 |
| **操作难度** | ⭐ 超简单 | ⭐⭐ 简单 |
| **时间** | ~5 分钟 | ~3 分钟 |
| **适合人群** | macOS/Linux 用户 | Windows 用户 |
| **自动化** | ✅ 完全自动 | ⚠️ 需手动 |

---

## 🎯 推荐流程

### 对于 macOS 用户（您）：
```
推荐：方法一（GitHub Actions）
理由：无需 Windows 环境，最方便
```

### 对于 Windows 用户：
```
推荐：方法二（手动）
理由：本地执行更快
```

### 对于团队协作：
```
推荐：方法一（GitHub Actions）
理由：标准化流程，可重复执行
```

---

## 🔒 安全提示

### ⚠️ 不要提交到 Git

以下文件包含私钥，**绝对不要**提交到 Git：

```gitignore
# 添加到 .gitignore
rustdesk-test-cert.pfx
rustdesk-test-cert-base64.txt
*.pfx
*-base64.txt
```

### ✅ GitHub Secrets 是安全的

- GitHub Secrets 使用加密存储
- 只能在工作流中访问
- 不会显示在日志中
- 无法通过 API 读取原始值

---

## 🧪 验证配置

配置完成后，验证证书是否生效：

### 检查 GitHub Secrets

1. 进入 `Settings` → `Secrets and variables` → `Actions`
2. 确认看到两个 secrets：
   - ✅ `WINDOWS_CERTIFICATE_BASE64`
   - ✅ `WINDOWS_CERTIFICATE_PASSWORD`

### 触发测试构建

```bash
# 创建一个空提交触发构建
git commit --allow-empty -m "测试证书签名"
git push
```

### 查看构建日志

1. 进入 `Actions` 标签
2. 查看最新的构建
3. 在 "Sign rustdesk files" 步骤中应该看到：
   ```
   ✅ 找到证书
   ✅ 签名成功
   ```

### 下载并验证应用

1. 构建完成后，从 Releases 下载 exe 文件
2. 在 Windows 上右键点击 → 属性 → 数字签名
3. 应该能看到签名信息：
   ```
   签名者: RustDesk Test Certificate
   ```

---

## 🎬 快速开始命令（方法一）

```bash
# 1. 提交工作流
git add .github/workflows/generate-test-certificate.yml
git commit -m "添加证书生成工作流"
git push

# 2. 然后在 GitHub 网页上：
#    Actions → Generate Test Certificate → Run workflow

# 3. 等待完成后下载 artifact

# 4. 配置 Secrets（在 GitHub 网页上）

# 5. 触发构建
git commit --allow-empty -m "开始签名构建"
git push
```

---

## 📚 相关文档

- [GENERATE_CERTIFICATE_INSTRUCTIONS.md](./GENERATE_CERTIFICATE_INSTRUCTIONS.md) - 详细的手动生成说明
- [QUICK_START.md](./QUICK_START.md) - 整体快速开始
- [WINDOWS_ONLY_BUILD_SETUP.md](./WINDOWS_ONLY_BUILD_SETUP.md) - 完整配置指南

---

## 🆘 需要帮助？

### 常见问题

**Q: 工作流运行失败？**  
A: 查看 Actions 日志中的详细错误信息

**Q: Artifact 下载是空的？**  
A: 检查工作流日志，确保证书生成步骤成功

**Q: 配置了 Secrets 但签名还是跳过？**  
A: 确保 Secret 名称完全匹配（区分大小写）

**Q: Base64 文件很长，全部复制吗？**  
A: 是的！必须复制全部内容，包括所有字符

---

**推荐：** 现在就使用方法一（GitHub Actions）生成证书吧！

🎯 **下一步操作：**
```bash
git add .
git commit -m "配置自动生成测试证书"
git push
```

然后在 GitHub Actions 页面点击 `Run workflow` ！

