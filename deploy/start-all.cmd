@echo off
REM ============================================================
REM  一键启动: copilot-api  +  cloudflared tunnel
REM  适合开发/手动场景。要做开机自启, 请用:
REM    install-cloudflared-service.cmd  (注册 cloudflared 为服务)
REM ============================================================
setlocal

set "PROJECT_DIR=%~dp0.."
set "ENV_FILE=%~dp0.env"

REM --- 加载 .env ---
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

if "%COPILOT_API_PORT%"=="" set "COPILOT_API_PORT=4141"

REM --- 检查依赖 ---
where bun >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] bun 未安装, 请先安装: https://bun.com/docs/installation#windows
    pause
    exit /b 1
)

where cloudflared >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] cloudflared 未安装, 请先运行 deploy\install-cloudflared.cmd
    pause
    exit /b 1
)

REM --- 启动 copilot-api (新窗口) ---
echo [INFO] 启动 copilot-api (端口 %COPILOT_API_PORT%)...
if defined PROXY_AUTH_TOKEN (
    echo [INFO] Bearer 校验: 已启用
) else (
    echo [WARN] Bearer 校验: 未启用 - 任何能访问域名的人都能调用 API!
)
start "copilot-api" cmd /k "cd /d %PROJECT_DIR% && set PROXY_AUTH_TOKEN=%PROXY_AUTH_TOKEN%&& bun run start --port %COPILOT_API_PORT%"

REM --- 等几秒让服务起来 ---
echo [INFO] 等待 copilot-api 就绪...
timeout /t 5 /nobreak >nul

REM --- 启动 cloudflared (新窗口) ---
echo [INFO] 启动 cloudflared tunnel...
start "cloudflared" cmd /k "cloudflared tunnel run --token %CLOUDFLARE_TUNNEL_TOKEN%"

echo.
echo ================================================
echo  [OK] 已启动两个窗口:
echo    1. copilot-api  -> http://localhost:%COPILOT_API_PORT%
echo    2. cloudflared  -> 你的域名 (在 Cloudflare 后台配置 Service:
echo                      http://localhost:%COPILOT_API_PORT%)
echo ================================================
echo.
echo 关闭对应窗口即可停止服务。
endlocal
