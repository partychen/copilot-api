@echo off
REM ============================================================
REM  把 cloudflared 注册成 Windows 服务 (开机自启, 后台运行)
REM  需要管理员权限
REM ============================================================
setlocal

REM --- 检查管理员 ---
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 需要以管理员身份运行此脚本。
    echo 右键 -> 以管理员身份运行
    pause
    exit /b 1
)

REM --- 加载 .env ---
set "ENV_FILE=%~dp0.env"
if not exist "%ENV_FILE%" (
    echo [ERROR] 找不到 %ENV_FILE%
    echo 请先复制 deploy\.env.example 为 deploy\.env 并填写 CLOUDFLARE_TUNNEL_TOKEN
    pause
    exit /b 1
)

for /f "usebackq tokens=1,2 delims==" %%A in ("%ENV_FILE%") do (
    set "%%A=%%B"
)

if "%CLOUDFLARE_TUNNEL_TOKEN%"=="" (
    echo [ERROR] deploy\.env 中 CLOUDFLARE_TUNNEL_TOKEN 为空
    pause
    exit /b 1
)

where cloudflared >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] cloudflared 未安装, 请先运行 install-cloudflared.cmd
    pause
    exit /b 1
)

echo [INFO] 注册 cloudflared 为 Windows 服务...
cloudflared service install %CLOUDFLARE_TUNNEL_TOKEN%
if %ERRORLEVEL%==0 (
    echo.
    echo [OK] 服务已安装并启动。可用以下命令管理:
    echo     net start  cloudflared
    echo     net stop   cloudflared
    echo     sc delete  cloudflared      :: 卸载
) else (
    echo [ERROR] 安装失败, 错误码 %ERRORLEVEL%
)

pause
endlocal
