@echo off
REM ============================================================
REM  一键卸载两个服务 (copilot-api + cloudflared)
REM  需要管理员权限
REM ============================================================
setlocal

net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 需要以管理员身份运行
    pause
    exit /b 1
)

echo [INFO] 停止并卸载 copilot-api...
nssm stop copilot-api confirm >nul 2>&1
nssm remove copilot-api confirm

echo.
echo [INFO] 停止并卸载 cloudflared...
net stop cloudflared >nul 2>&1
cloudflared service uninstall >nul 2>&1
sc delete cloudflared >nul 2>&1

echo.
echo [OK] 两个服务已卸载
pause
endlocal
