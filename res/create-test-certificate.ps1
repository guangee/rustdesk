# RustDesk Windows 测试签名证书生成脚本
# 用于开发和测试环境，生产环境请使用正式的代码签名证书

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RustDesk 测试签名证书生成工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 配置证书参数
$certSubject = "CN=RustDesk Test Certificate, O=RustDesk Test, C=US"
$certPassword = "RustDeskTest2024!"
$outputPath = "rustdesk-test-cert.pfx"

Write-Host "[1/4] 创建自签名证书..." -ForegroundColor Yellow

# 创建自签名证书
$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject $certSubject `
    -KeyUsage DigitalSignature `
    -FriendlyName "RustDesk Test Code Signing Certificate" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}") `
    -NotAfter (Get-Date).AddYears(5)

if (-not $cert) {
    Write-Host "❌ 证书创建失败！" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 证书创建成功" -ForegroundColor Green
Write-Host "   Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
Write-Host ""

Write-Host "[2/4] 导出证书为 PFX 格式..." -ForegroundColor Yellow

# 导出为 PFX
$password = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
try {
    Export-PfxCertificate -Cert $cert -FilePath $outputPath -Password $password | Out-Null
    Write-Host "✅ PFX 导出成功: $outputPath" -ForegroundColor Green
} catch {
    Write-Host "❌ PFX 导出失败: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "[3/4] 转换为 Base64 编码..." -ForegroundColor Yellow

# 转换为 Base64
try {
    $base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($outputPath))
    $base64 | Out-File "rustdesk-test-cert-base64.txt"
    Write-Host "✅ Base64 编码成功: rustdesk-test-cert-base64.txt" -ForegroundColor Green
} catch {
    Write-Host "❌ Base64 转换失败: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "[4/4] 生成配置摘要..." -ForegroundColor Yellow
Write-Host ""

# 显示配置信息
Write-Host "========================================" -ForegroundColor Green
Write-Host "  证书配置信息" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📁 生成的文件:" -ForegroundColor Cyan
Write-Host "   • $outputPath" -ForegroundColor White
Write-Host "   • rustdesk-test-cert-base64.txt" -ForegroundColor White
Write-Host ""
Write-Host "🔐 GitHub Secrets 配置:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Secret 名称: WINDOWS_CERTIFICATE_BASE64" -ForegroundColor Yellow
Write-Host "   Secret 值: (请复制 rustdesk-test-cert-base64.txt 的内容)" -ForegroundColor Gray
Write-Host ""
Write-Host "   Secret 名称: WINDOWS_CERTIFICATE_PASSWORD" -ForegroundColor Yellow
Write-Host "   Secret 值: $certPassword" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 配置步骤:" -ForegroundColor Cyan
Write-Host "   1. 打开 GitHub 仓库" -ForegroundColor White
Write-Host "   2. 进入 Settings -> Secrets and variables -> Actions" -ForegroundColor White
Write-Host "   3. 点击 'New repository secret'" -ForegroundColor White
Write-Host "   4. 添加上述两个 secrets" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  重要提示:" -ForegroundColor Red
Write-Host "   • 这是测试证书，用户仍会看到安全警告" -ForegroundColor Yellow
Write-Host "   • 生产环境请使用正式的代码签名证书" -ForegroundColor Yellow
Write-Host "   • 证书密码: $certPassword" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ 证书生成完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

