# 工作流签名配置修改指南

本文档说明如何修改 `.github/workflows/flutter-build.yml` 以支持直接在 GitHub Actions 中进行代码签名。

## 方案对比

### 当前方案（远程签名服务器）
- ✅ 私钥不暴露在 GitHub Actions
- ❌ 需要自己搭建和维护签名服务器
- ❌ 配置复杂
- ❌ 依赖外部服务

### 推荐方案（直接签名）
- ✅ 配置简单，无需外部服务
- ✅ GitHub Secrets 加密存储证书
- ✅ 主流开源项目的标准做法
- ⚠️ 证书以加密形式存储在 GitHub（安全性由 GitHub 保障）

---

## Windows 签名修改

### 修改位置 1：build-for-windows-flutter job (第 236-241 行)

**原代码：**
```yaml
- name: Sign rustdesk files
  if: env.UPLOAD_ARTIFACT == 'true' && env.SIGN_BASE_URL != ''
  shell: bash
  run: |
    pip3 install requests argparse
    BASE_URL=${{ secrets.SIGN_BASE_URL }} SECRET_KEY=${{ secrets.SIGN_SECRET_KEY }} python3 res/job.py sign_files ./rustdesk/
```

**修改为：**
```yaml
- name: Import code signing certificate
  if: env.UPLOAD_ARTIFACT == 'true' && env.WINDOWS_CERTIFICATE_BASE64 != ''
  shell: powershell
  run: |
    # 解码证书
    $pfxBytes = [System.Convert]::FromBase64String("${{ secrets.WINDOWS_CERTIFICATE_BASE64 }}")
    $pfxPath = Join-Path -Path $env:TEMP -ChildPath "certificate.pfx"
    [IO.File]::WriteAllBytes($pfxPath, $pfxBytes)
    
    # 导入证书到当前用户存储
    $password = ConvertTo-SecureString -String "${{ secrets.WINDOWS_CERTIFICATE_PASSWORD }}" -AsPlainText -Force
    Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My -Password $password
    
    # 清理临时文件
    Remove-Item $pfxPath
  env:
    WINDOWS_CERTIFICATE_BASE64: ${{ secrets.WINDOWS_CERTIFICATE_BASE64 }}

- name: Sign rustdesk files
  if: env.UPLOAD_ARTIFACT == 'true' && env.WINDOWS_CERTIFICATE_BASE64 != ''
  shell: powershell
  run: |
    # 获取证书指纹
    $cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
    
    # 签名所有 exe 和 dll 文件
    Get-ChildItem -Path ./rustdesk -Recurse -Include *.exe,*.dll | ForEach-Object {
      Write-Host "Signing $($_.FullName)"
      & "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign `
        /fd SHA256 `
        /sha1 $cert.Thumbprint `
        /t http://timestamp.digicert.com `
        /v `
        $_.FullName
    }
  env:
    WINDOWS_CERTIFICATE_BASE64: ${{ secrets.WINDOWS_CERTIFICATE_BASE64 }}
```

### 修改位置 2：build-for-windows-flutter job (第 268-272 行)

**原代码：**
```yaml
- name: Sign rustdesk self-extracted file
  if: env.UPLOAD_ARTIFACT == 'true' && env.SIGN_BASE_URL != ''
  shell: bash
  run: |
    BASE_URL=${{ secrets.SIGN_BASE_URL }} SECRET_KEY=${{ secrets.SIGN_SECRET_KEY }} python3 res/job.py sign_files ./SignOutput
```

**修改为：**
```yaml
- name: Sign rustdesk self-extracted file and MSI
  if: env.UPLOAD_ARTIFACT == 'true' && env.WINDOWS_CERTIFICATE_BASE64 != ''
  shell: powershell
  run: |
    # 获取证书指纹
    $cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
    
    # 签名 exe 和 msi 文件
    Get-ChildItem -Path ./SignOutput -Recurse -Include *.exe,*.msi | ForEach-Object {
      Write-Host "Signing $($_.FullName)"
      & "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign `
        /fd SHA256 `
        /sha1 $cert.Thumbprint `
        /t http://timestamp.digicert.com `
        /v `
        $_.FullName
    }
  env:
    WINDOWS_CERTIFICATE_BASE64: ${{ secrets.WINDOWS_CERTIFICATE_BASE64 }}
```

### 修改位置 3：build-for-windows-sciter job (第 402-407 行)

对 Sciter 版本应用相同的修改。

### 修改位置 4：更新环境变量检查 (第 45-48 行)

**原代码：**
```yaml
ANDROID_SIGNING_KEY: "${{ secrets.ANDROID_SIGNING_KEY }}"
MACOS_P12_BASE64: "${{ secrets.MACOS_P12_BASE64 }}"
UPLOAD_ARTIFACT: "${{ inputs.upload-artifact }}"
SIGN_BASE_URL: "${{ secrets.SIGN_BASE_URL }}"
```

**修改为：**
```yaml
ANDROID_SIGNING_KEY: "${{ secrets.ANDROID_SIGNING_KEY }}"
MACOS_P12_BASE64: "${{ secrets.MACOS_P12_BASE64 }}"
WINDOWS_CERTIFICATE_BASE64: "${{ secrets.WINDOWS_CERTIFICATE_BASE64 }}"
UPLOAD_ARTIFACT: "${{ inputs.upload-artifact }}"
```

---

## macOS 签名修改说明

macOS 部分已经配置正确！当前工作流已经支持：

1. ✅ **代码签名**（第 728-742 行）：使用 codesign
2. ✅ **公证**（第 744 行）：使用 rcodesign notary-submit

**您只需要配置以下 GitHub Secrets：**
- `MACOS_P12_BASE64` - 已在工作流中使用 ✅
- `MACOS_P12_PASSWORD` - 已在工作流中使用 ✅
- `MACOS_CODESIGN_IDENTITY` - 已在工作流中使用 ✅
- `MACOS_NOTARIZE_JSON` - 已在工作流中使用 ✅

无需修改 macOS 相关代码！

---

## 完整修改示例

### 创建一个新的签名步骤文件

为了更好地管理代码，建议创建一个可重用的签名脚本：

**创建文件：`res/sign-windows.ps1`**

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$CertificateBase64,
    
    [Parameter(Mandatory=$true)]
    [string]$CertificatePassword,
    
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

# 解码并导入证书
$pfxBytes = [System.Convert]::FromBase64String($CertificateBase64)
$pfxPath = Join-Path -Path $env:TEMP -ChildPath "temp_cert.pfx"
[IO.File]::WriteAllBytes($pfxPath, $pfxBytes)

$password = ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force
Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My -Password $password | Out-Null

# 获取证书
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1

if (-not $cert) {
    Write-Error "No code signing certificate found!"
    exit 1
}

Write-Host "Using certificate: $($cert.Subject)"
Write-Host "Thumbprint: $($cert.Thumbprint)"

# 查找 signtool
$signtoolPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64\signtool.exe"
)

$signtool = $null
foreach ($path in $signtoolPaths) {
    if (Test-Path $path) {
        $signtool = $path
        break
    }
}

if (-not $signtool) {
    # 尝试在 PATH 中查找
    $signtool = (Get-Command signtool.exe -ErrorAction SilentlyContinue).Source
}

if (-not $signtool) {
    Write-Error "signtool.exe not found!"
    exit 1
}

Write-Host "Using signtool: $signtool"

# 签名文件
$filesToSign = Get-ChildItem -Path $FilePath -Recurse -Include *.exe,*.dll,*.msi | Where-Object { -not $_.PSIsContainer }

foreach ($file in $filesToSign) {
    Write-Host "Signing: $($file.FullName)"
    
    $result = & $signtool sign `
        /fd SHA256 `
        /sha1 $cert.Thumbprint `
        /t http://timestamp.digicert.com `
        /v `
        $file.FullName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to sign $($file.FullName)"
        exit 1
    }
    
    Write-Host "Successfully signed: $($file.Name)" -ForegroundColor Green
}

# 清理
Remove-Item $pfxPath -Force
Write-Host "`nSigning completed successfully!" -ForegroundColor Green
```

### 在工作流中使用脚本

```yaml
- name: Sign Windows files
  if: env.UPLOAD_ARTIFACT == 'true' && env.WINDOWS_CERTIFICATE_BASE64 != ''
  shell: powershell
  run: |
    ./res/sign-windows.ps1 `
      -CertificateBase64 "${{ secrets.WINDOWS_CERTIFICATE_BASE64 }}" `
      -CertificatePassword "${{ secrets.WINDOWS_CERTIFICATE_PASSWORD }}" `
      -FilePath "./rustdesk"
  env:
    WINDOWS_CERTIFICATE_BASE64: ${{ secrets.WINDOWS_CERTIFICATE_BASE64 }}
```

---

## 简化版修改（最小改动）

如果您不想创建新脚本，可以使用这个简化版本直接替换现有的签名步骤：

### 替换第 236-241 行

```yaml
- name: Sign rustdesk files with Windows certificate
  if: env.UPLOAD_ARTIFACT == 'true'
  shell: powershell
  run: |
    if ("${{ secrets.WINDOWS_CERTIFICATE_BASE64 }}" -eq "") {
      Write-Host "No Windows certificate configured, skipping signing"
      exit 0
    }
    
    # 导入证书
    $pfx = [Convert]::FromBase64String("${{ secrets.WINDOWS_CERTIFICATE_BASE64 }}")
    $pfxPath = "$env:TEMP\cert.pfx"
    [IO.File]::WriteAllBytes($pfxPath, $pfx)
    $pwd = ConvertTo-SecureString "${{ secrets.WINDOWS_CERTIFICATE_PASSWORD }}" -AsPlainText -Force
    Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My -Password $pwd
    
    # 签名
    $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
    Get-ChildItem ./rustdesk -Recurse -Include *.exe,*.dll | ForEach-Object {
      signtool sign /fd SHA256 /sha1 $cert.Thumbprint /t http://timestamp.digicert.com $_.FullName
    }
    
    Remove-Item $pfxPath
```

---

## 测试签名

### 本地测试（Windows）

```powershell
# 1. 安装 Windows SDK（包含 signtool.exe）
# 下载地址：https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/

# 2. 验证签名
signtool verify /pa /v "path\to\rustdesk.exe"

# 3. 查看签名信息
Get-AuthenticodeSignature "path\to\rustdesk.exe" | Format-List *
```

### 本地测试（macOS）

```bash
# 验证签名
codesign -vvv --deep --strict RustDesk.app

# 验证公证
spctl -a -vvv RustDesk.app

# 查看签名信息
codesign -dvvv RustDesk.app
```

---

## 常见问题排查

### Windows 签名失败

**问题：** `signtool.exe not found`
**解决：** 安装 Windows SDK 或更新工作流中 signtool 的路径

**问题：** `Certificate not found`
**解决：** 检查 WINDOWS_CERTIFICATE_BASE64 是否正确配置

**问题：** `Timestamp server not available`
**解决：** 更换时间戳服务器：
- http://timestamp.digicert.com
- http://timestamp.sectigo.com
- http://timestamp.globalsign.com

### macOS 公证失败

**问题：** `Unable to upload to notary service`
**解决：** 检查 MACOS_NOTARIZE_JSON 配置是否正确

**问题：** `Gatekeeper still blocks the app`
**解决：** 确保运行了 `stapler` 命令将公证票据附加到 DMG

---

## 下一步

1. ✅ 按照 `SIGNING_GUIDE.md` 获取证书
2. ✅ 配置 GitHub Secrets
3. ✅ 应用本文档中的工作流修改
4. ✅ 提交并推送代码
5. ✅ 查看 GitHub Actions 运行结果

如有问题，请查看 GitHub Actions 日志中的详细错误信息。

