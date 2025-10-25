# Windows 代码签名脚本
# 用于在 GitHub Actions 或本地环境中签名 Windows 可执行文件

param(
    [Parameter(Mandatory=$false)]
    [string]$CertificateBase64 = $env:WINDOWS_CERTIFICATE_BASE64,
    
    [Parameter(Mandatory=$false)]
    [string]$CertificatePassword = $env:WINDOWS_CERTIFICATE_PASSWORD,
    
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RustDesk Windows 代码签名工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查参数
if ([string]::IsNullOrEmpty($CertificateBase64)) {
    Write-Host "❌ 错误: 未提供证书 (WINDOWS_CERTIFICATE_BASE64)" -ForegroundColor Red
    Write-Host "   请设置环境变量或通过参数传递" -ForegroundColor Yellow
    exit 1
}

if ([string]::IsNullOrEmpty($CertificatePassword)) {
    Write-Host "❌ 错误: 未提供证书密码 (WINDOWS_CERTIFICATE_PASSWORD)" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $FilePath)) {
    Write-Host "❌ 错误: 路径不存在: $FilePath" -ForegroundColor Red
    exit 1
}

Write-Host "[1/5] 解码并导入证书..." -ForegroundColor Yellow

# 创建临时证书文件
try {
    $pfxBytes = [System.Convert]::FromBase64String($CertificateBase64)
    $pfxPath = Join-Path -Path $env:TEMP -ChildPath "rustdesk_temp_cert_$([Guid]::NewGuid().ToString()).pfx"
    [IO.File]::WriteAllBytes($pfxPath, $pfxBytes)
    Write-Host "✅ 证书解码成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 证书解码失败: $_" -ForegroundColor Red
    exit 1
}

# 导入证书到用户存储
try {
    $password = ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force
    $importedCert = Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My -Password $password -Exportable
    Write-Host "✅ 证书导入成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 证书导入失败: $_" -ForegroundColor Red
    Remove-Item $pfxPath -Force -ErrorAction SilentlyContinue
    exit 1
} finally {
    # 清理临时文件
    if (Test-Path $pfxPath) {
        Remove-Item $pfxPath -Force
    }
}

Write-Host ""
Write-Host "[2/5] 查找证书..." -ForegroundColor Yellow

# 获取代码签名证书
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | 
        Where-Object { $_.Thumbprint -eq $importedCert.Thumbprint } | 
        Select-Object -First 1

if (-not $cert) {
    Write-Host "❌ 未找到代码签名证书" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 找到证书" -ForegroundColor Green
Write-Host "   主题: $($cert.Subject)" -ForegroundColor Gray
Write-Host "   指纹: $($cert.Thumbprint)" -ForegroundColor Gray
Write-Host "   有效期: $($cert.NotBefore.ToString('yyyy-MM-dd')) 至 $($cert.NotAfter.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
Write-Host ""

Write-Host "[3/5] 查找 signtool.exe..." -ForegroundColor Yellow

# 查找 signtool.exe
$signtoolPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.17763.0\x64\signtool.exe"
)

$signtool = $null
foreach ($path in $signtoolPaths) {
    if (Test-Path $path) {
        $signtool = $path
        break
    }
}

# 如果找不到，尝试从 PATH 中查找
if (-not $signtool) {
    $signtool = (Get-Command signtool.exe -ErrorAction SilentlyContinue).Source
}

if (-not $signtool) {
    Write-Host "❌ 未找到 signtool.exe" -ForegroundColor Red
    Write-Host "   请安装 Windows SDK: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ 找到 signtool: $signtool" -ForegroundColor Green
Write-Host ""

Write-Host "[4/5] 扫描需要签名的文件..." -ForegroundColor Yellow

# 查找所有需要签名的文件
$extensions = @('*.exe', '*.dll', '*.msi', '*.sys')
$filesToSign = @()

if (Test-Path $FilePath -PathType Container) {
    # 如果是目录，扫描所有符合条件的文件
    foreach ($ext in $extensions) {
        $filesToSign += Get-ChildItem -Path $FilePath -Recurse -Include $ext -File
    }
} else {
    # 如果是单个文件
    $filesToSign += Get-Item $FilePath
}

if ($filesToSign.Count -eq 0) {
    Write-Host "⚠️  警告: 未找到需要签名的文件" -ForegroundColor Yellow
    exit 0
}

Write-Host "✅ 找到 $($filesToSign.Count) 个文件需要签名" -ForegroundColor Green
Write-Host ""

Write-Host "[5/5] 开始签名..." -ForegroundColor Yellow
Write-Host ""

# 时间戳服务器列表（备用）
$timestampServers = @(
    "http://timestamp.digicert.com",
    "http://timestamp.sectigo.com",
    "http://timestamp.globalsign.com/tsa/r6advanced1",
    "http://time.certum.pl"
)

$successCount = 0
$failCount = 0

foreach ($file in $filesToSign) {
    Write-Host "  签名: $($file.Name)" -ForegroundColor Cyan
    
    $signed = $false
    $lastError = $null
    
    # 尝试使用不同的时间戳服务器
    foreach ($tsServer in $timestampServers) {
        try {
            $signResult = & $signtool sign `
                /fd SHA256 `
                /sha1 $cert.Thumbprint `
                /t $tsServer `
                /v `
                $file.FullName 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ 签名成功 (时间戳: $tsServer)" -ForegroundColor Green
                $successCount++
                $signed = $true
                break
            } else {
                $lastError = $signResult
            }
        } catch {
            $lastError = $_
        }
    }
    
    if (-not $signed) {
        Write-Host "  ❌ 签名失败: $($file.Name)" -ForegroundColor Red
        if ($lastError) {
            Write-Host "     错误: $lastError" -ForegroundColor Gray
        }
        $failCount++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  签名完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  成功: $successCount" -ForegroundColor Green
Write-Host "  失败: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 清理证书（可选，GitHub Actions 环境会自动清理）
try {
    Remove-Item -Path "Cert:\CurrentUser\My\$($cert.Thumbprint)" -Force -ErrorAction SilentlyContinue
} catch {
    # 忽略清理错误
}

if ($failCount -gt 0) {
    exit 1
}

exit 0

