# Node.js 应用一键部署脚本 (PowerShell版本)
# 适用于 webhostmost.com 平台

param(
    [Parameter(Mandatory=$true)]
    [string]$Server,
    
    [Parameter(Mandatory=$true)]
    [string]$Domain,
    
    [Parameter(Mandatory=$true)]
    [string]$Package
)

# 颜色函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "   Node.js 应用一键部署脚本" "Cyan"
Write-ColorOutput "========================================" "Cyan"

Write-ColorOutput "部署配置:" "Yellow"
Write-ColorOutput "  服务器: $Server" "Yellow"
Write-ColorOutput "  域名: $Domain" "Yellow"
Write-ColorOutput "  部署包: $Package" "Yellow"
Write-Host ""

# 检查部署包是否存在
if (-not (Test-Path $Package)) {
    Write-ColorOutput "错误: 部署包 $Package 不存在" "Red"
    exit 1
}

try {
    # 1. 分析平台环境
    Write-ColorOutput "[1/7] 分析平台环境..." "Green"
    $Username = ssh $Server "whoami"
    $NodePath = ssh $Server "ls /opt/alt/alt-nodejs20/root/usr/bin/node 2>/dev/null || echo '/opt/alt/alt-nodejs18/root/usr/bin/node'"
    
    Write-ColorOutput "  用户名: $Username" "Green"
    Write-ColorOutput "  Node.js: $NodePath" "Green"
    
    # 2. 检查目录结构
    Write-ColorOutput "[2/7] 检查目录结构..." "Green"
    ssh $Server "ls -la ~/domains/$Domain/ 2>/dev/null || echo '目录不存在'"
    
    # 3. 清理目标目录
    Write-ColorOutput "[3/7] 清理目标目录..." "Green"
    ssh $Server "cd ~/domains/$Domain/public_html 2>/dev/null && rm -f index.html favicon.svg && rm -rf cgi-bin || echo '目录为空'"
    
    # 4. 上传部署包
    Write-ColorOutput "[4/7] 上传部署包..." "Green"
    scp $Package "${Server}:~/"
    Write-ColorOutput "  上传完成" "Green"
    
    # 5. 解压到目标目录
    Write-ColorOutput "[5/7] 解压部署包..." "Green"
    $PackageName = Split-Path $Package -Leaf
    ssh $Server "cd ~/domains/$Domain/public_html && tar -xzf ~/$PackageName"
    Write-ColorOutput "  解压完成" "Green"
    
    # 6. 配置.htaccess
    Write-ColorOutput "[6/7] 配置.htaccess..." "Green"
    $HtaccessContent = @"
PassengerEnabled On
PassengerAppRoot /home/$Username/domains/$Domain/public_html
PassengerStartupFile app.js
PassengerAppType node
PassengerNodejs $NodePath
PassengerAppEnv production

SetEnv NODE_ENV production
"@
    
    ssh $Server "cd ~/domains/$Domain/public_html && cat > .htaccess << 'EOF'
$HtaccessContent
EOF"
    Write-ColorOutput "  配置完成" "Green"
    
    # 7. 启动应用
    Write-ColorOutput "[7/7] 启动应用..." "Green"
    ssh $Server "cd ~/domains/$Domain/public_html && touch tmp/restart.txt"
    Write-ColorOutput "  启动完成" "Green"
    
    # 验证部署
    Write-ColorOutput "验证部署结果..." "Green"
    Start-Sleep -Seconds 5
    $HttpStatus = ssh $Server "curl -s -o /dev/null -w '%{http_code}' http://$Domain/"
    
    if ($HttpStatus -eq "200") {
        Write-ColorOutput "✅ HTTP访问正常 (200)" "Green"
    } else {
        Write-ColorOutput "❌ HTTP访问异常 ($HttpStatus)" "Red"
    }
    
    Write-Host ""
    Write-ColorOutput "========================================" "Green"
    Write-ColorOutput "   部署完成！" "Green"
    Write-ColorOutput "========================================" "Green"
    Write-Host ""
    Write-ColorOutput "访问信息:" "Cyan"
    Write-ColorOutput "  🌐 网站地址: http://$Domain/" "Cyan"
    Write-ColorOutput "  🔧 管理后台: http://$Domain/admin" "Cyan"
    Write-ColorOutput "  📡 API接口: http://$Domain/api/menus" "Cyan"
    Write-ColorOutput "  🔑 默认账号: admin / 123456" "Cyan"
    Write-Host ""
    Write-ColorOutput "⚠️  请立即修改默认密码！" "Yellow"
    
} catch {
    Write-ColorOutput "部署过程中发生错误: $($_.Exception.Message)" "Red"
    exit 1
}
