@echo off
REM ============================================================
REM  安装 cloudflared (Cloudflare Tunnel 客户端)
REM  优先用 winget; 没有则提示手动下载链接
REM ============================================================

where cloudflared >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [OK] cloudflared 已安装:
    cloudflared --version
    goto :eof
)

echo [INFO] cloudflared 未安装, 尝试用 winget 安装...
where winget >nul 2>&1
if %ERRORLEVEL%==0 (
    winget install --id Cloudflare.cloudflared -e --accept-source-agreements --accept-package-agreements
    if %ERRORLEVEL%==0 (
        echo.
        echo [OK] 安装完成。请重开一个终端让 PATH 生效, 然后运行 start-all.cmd
        goto :eof
    )
)

echo.
echo [WARN] 自动安装失败, 请手动下载:
echo   https://github.com/cloudflare/cloudflared/releases/latest
echo 下载 cloudflared-windows-amd64.exe, 重命名为 cloudflared.exe,
echo 放到 PATH 路径下 (例如 C:\Windows\System32\)
pause
