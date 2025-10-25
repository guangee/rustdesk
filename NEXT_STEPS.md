# 🎯 接下来的操作步骤

已为您配置好所有文件！现在按照以下步骤操作：

---

## 📝 第一步：提交并推送代码

```bash
cd /Volumes/ExtendedSpace/Projects/IdeaProjects/rustdesk

# 查看将要提交的更改
git status

# 提交所有更改
git commit -m "配置 Windows 测试签名 + 自动证书生成"

# 推送到 GitHub
git push
```

---

## 🔐 第二步：在 GitHub 上生成证书

### 2.1 访问 GitHub Actions

1. 打开浏览器，访问您的 GitHub 仓库
2. 点击顶部的 **`Actions`** 标签

### 2.2 运行证书生成工作流

1. 在左侧工作流列表中，找到 **`Generate Test Certificate`**
2. 点击它
3. 在右侧看到 **`Run workflow`** 按钮（灰色下拉按钮）
4. 点击下拉按钮，会展开显示 **`Run workflow`**（绿色按钮）
5. 点击绿色的 **`Run workflow`** 按钮

### 2.3 等待工作流完成

- ⏱️ 预计时间：1-2 分钟
- ✅ 完成后，状态会显示绿色的 ✓

### 2.4 下载证书文件

1. 点击刚完成的工作流运行记录
2. 向下滚动到页面底部
3. 在 **`Artifacts`** 部分找到 **`test-certificate`**
4. 点击它下载（会下载一个 zip 文件）
5. 解压 zip 文件，得到 **`rustdesk-test-cert-base64.txt`**

---

## 🔑 第三步：配置 GitHub Secrets

### 3.1 进入 Secrets 设置

1. 在仓库页面，点击 **`Settings`** 标签
2. 在左侧菜单中，点击 **`Secrets and variables`** → **`Actions`**

### 3.2 添加第一个 Secret

1. 点击右上角的 **`New repository secret`** 按钮
2. 填写：
   - **Name**: `WINDOWS_CERTIFICATE_BASE64`
   - **Value**: 
     - 打开刚才下载的 `rustdesk-test-cert-base64.txt`
     - 全选所有内容（Cmd+A）
     - 复制（Cmd+C）
     - 粘贴到这里（Cmd+V）
3. 点击 **`Add secret`** 按钮

### 3.3 添加第二个 Secret

1. 再次点击 **`New repository secret`**
2. 填写：
   - **Name**: `WINDOWS_CERTIFICATE_PASSWORD`
   - **Value**: `RustDeskTest2024!`
3. 点击 **`Add secret`** 按钮

### 3.4 验证配置

确认您看到两个 secrets：
- ✅ `WINDOWS_CERTIFICATE_BASE64`
- ✅ `WINDOWS_CERTIFICATE_PASSWORD`

---

## 🚀 第四步：触发构建

现在所有配置都完成了，触发一次构建来测试：

```bash
# 方法 1：创建空提交触发
git commit --allow-empty -m "测试 Windows 签名构建"
git push

# 方法 2：或者在 GitHub Actions 中手动触发
# 进入 Actions → 选择构建工作流 → Run workflow
```

---

## 📊 第五步：查看构建结果

### 5.1 监控构建过程

1. 进入 **`Actions`** 标签
2. 点击最新的构建运行记录
3. 查看构建进度

### 5.2 检查签名步骤

展开 **`Sign rustdesk files`** 步骤，应该看到：

```
========================================
  RustDesk Windows 代码签名工具
========================================

[1/5] 解码并导入证书...
✅ 证书解码成功
✅ 证书导入成功

[2/5] 查找证书...
✅ 找到证书
   主题: CN=RustDesk Test Certificate...
   
[3/5] 查找 signtool.exe...
✅ 找到 signtool

[4/5] 扫描需要签名的文件...
✅ 找到 XX 个文件需要签名

[5/5] 开始签名...
  ✅ 签名成功: rustdesk.exe
  ✅ 签名成功: xxx.dll
  ...

========================================
  签名完成
========================================
  成功: XX
  失败: 0
```

### 5.3 下载构建产物

构建完成后：
1. 进入仓库的 **`Releases`** 页面
2. 找到最新的 release（tag: nightly）
3. 下载：
   - `rustdesk-1.4.3-x86_64.exe` ✅ 已签名
   - `rustdesk-1.4.3-x86_64.msi` ✅ 已签名
   - `rustdesk-1.4.3-x86-sciter.exe` ✅ 已签名

---

## ✅ 第六步：验证签名

在 Windows 机器上验证（如果有的话）：

### 方法 1：查看文件属性
1. 右键点击下载的 exe 文件
2. 选择 **属性**
3. 切换到 **数字签名** 标签
4. 应该能看到：
   ```
   签名者列表：
     RustDesk Test Certificate
   ```

### 方法 2：PowerShell 验证
```powershell
Get-AuthenticodeSignature .\rustdesk-1.4.3-x86_64.exe | Format-List *
```

应该显示：
```
SignerCertificate : [Subject]
                      CN=RustDesk Test Certificate, O=RustDesk Test, C=US
Status           : Valid
```

---

## 📋 完整操作清单

请按顺序完成：

- [ ] **步骤 1**: 提交并推送代码
  ```bash
  git commit -m "配置 Windows 测试签名"
  git push
  ```

- [ ] **步骤 2**: 在 GitHub Actions 生成证书
  - [ ] 进入 Actions 页面
  - [ ] 运行 "Generate Test Certificate" 工作流
  - [ ] 等待完成（1-2 分钟）
  - [ ] 下载 artifact (test-certificate)
  - [ ] 解压得到 rustdesk-test-cert-base64.txt

- [ ] **步骤 3**: 配置 GitHub Secrets
  - [ ] 进入 Settings → Secrets → Actions
  - [ ] 添加 `WINDOWS_CERTIFICATE_BASE64`
  - [ ] 添加 `WINDOWS_CERTIFICATE_PASSWORD` = `RustDeskTest2024!`

- [ ] **步骤 4**: 触发构建
  ```bash
  git commit --allow-empty -m "测试签名"
  git push
  ```

- [ ] **步骤 5**: 验证构建
  - [ ] 查看 Actions 日志中的签名步骤
  - [ ] 确认所有文件签名成功
  - [ ] 从 Releases 下载应用

- [ ] **步骤 6**: （可选）在 Windows 上验证签名

---

## 🎉 成功标志

完成后，您应该：

✅ GitHub Actions 构建成功  
✅ 签名步骤显示绿色的 ✓  
✅ Releases 中有已签名的 exe/msi 文件  
✅ （可选）Windows 上能看到数字签名  

---

## ⏱️ 预计总时间

- 步骤 1-3: ~5 分钟（第一次配置）
- 步骤 4-6: ~30-45 分钟（构建时间）

---

## 🆘 遇到问题？

### 常见问题速查

**Q: 工作流找不到？**  
A: 确保已推送代码，刷新 Actions 页面

**Q: 工作流运行失败？**  
A: 查看日志中的错误信息，通常是权限问题

**Q: 签名步骤被跳过？**  
A: 检查 Secrets 名称是否正确（区分大小写）

**Q: 下载的应用显示"未签名"？**  
A: 查看构建日志，确认签名步骤成功执行

---

## 📚 参考文档

需要更多信息？查看：

- [CERTIFICATE_GENERATION_GUIDE.md](./CERTIFICATE_GENERATION_GUIDE.md) - 证书生成详细指南
- [QUICK_START.md](./QUICK_START.md) - 快速开始
- [WINDOWS_ONLY_BUILD_SETUP.md](./WINDOWS_ONLY_BUILD_SETUP.md) - 完整配置说明

---

**准备好了吗？** 

现在就开始第一步：
```bash
git commit -m "配置 Windows 测试签名 + 自动证书生成"
git push
```

🚀 **祝您构建顺利！**

