<#
  DeepSeek Harness 一键启动器
  由桌面上的「启动 DeepSeek Harness.bat」调用，也可以直接右键用 PowerShell 运行。

  行为：
    * 服务未运行 -> 启动服务，就绪后自动打开客户端页面
    * 服务已运行 -> 直接打开客户端页面
  服务日志显示在本控制台窗口；关闭窗口即停止服务。
#>

$ErrorActionPreference = 'Stop'

# ---------------- 可按需修改 ----------------
$DshRoot = 'E:\工作区\code\deepseek-harness'
$Port    = 3080
# -------------------------------------------

$Url = "http://127.0.0.1:$Port/"
$Tag = '[DeepSeek Harness]'

try { $Host.UI.RawUI.WindowTitle = 'DeepSeek Harness' } catch { }

if (-not (Test-Path -LiteralPath (Join-Path $DshRoot 'package.json'))) {
    Write-Host "$Tag 错误：找不到 DeepSeek Harness 目录："
    Write-Host "                    $DshRoot"
    Write-Host "                    请用记事本打开本脚本，修改开头 DshRoot 那一行。"
    Write-Host ''
    Read-Host '按回车键退出'
    exit 1
}

if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "$Tag 错误：找不到 pnpm 命令。"
    Write-Host '                    请确认已安装 Node.js 与 pnpm，且都在 PATH 中。'
    Write-Host ''
    Read-Host '按回车键退出'
    exit 1
}

# 探测端口状态：dsh=本服务在运行  other=被别的程序占用  none=无人监听
function Get-DshPortState {
    $code = 0
    $body = ''
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -MaximumRedirection 0 -TimeoutSec 4
        $code = [int]$response.StatusCode
        $body = [string]$response.Content
    } catch {
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
    }
    if ($code -eq 401 -or $body.Contains('__DSH_BOOT__')) { return 'dsh' }
    try {
        $client = New-Object Net.Sockets.TcpClient
        $client.Connect('127.0.0.1', $Port)
        $client.Close()
        return 'other'
    } catch {
        return 'none'
    }
}

switch (Get-DshPortState) {
    'dsh' {
        Write-Host "$Tag 服务已在运行，正在打开客户端页面："
        Write-Host "                    $Url"
        Start-Process $Url
        Start-Sleep -Seconds 2
        exit 0
    }
    'other' {
        Write-Host "$Tag 端口 $Port 已被占用（也可能服务仍在启动中）。"
        Write-Host "                    仍尝试打开页面：$Url"
        Write-Host "                    若页面不是 DeepSeek Harness，请先结束占用 $Port 的程序。"
        Start-Process $Url
        Write-Host ''
        Read-Host '按回车键退出'
        exit 1
    }
    default {
        Write-Host "$Tag 正在启动，就绪后会自动打开客户端页面（首次约十几秒）..."
        Write-Host "                    客户端地址：$Url"
        Write-Host '                    关闭本窗口即停止服务。'
        Write-Host ''
        Set-Location -LiteralPath $DshRoot
        & pnpm dsh web --port $Port
        Write-Host ''
        Write-Host "$Tag 服务已退出。"
        Read-Host '按回车键退出'
        exit 0
    }
}
