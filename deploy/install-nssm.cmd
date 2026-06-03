@echo off
REM ============================================================
REM  安装 nssm (Non-Sucking Service Manager)
REM  用它把任意命令包成 Windows 服务
REM ============================================================

where nssm >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [OK] nssm 已安装:
    nssm version
    goto :eof
)

echo [INFO] nssm 未安装, 尝试用 winget 安装...
where winget >nul 2>&1
if %ERRORLEVEL%==0 (
    winget install --id NSSM.NSSM -e --accept-source-agreements --accept-package-agreements
    if %ERRORLEVEL%==0 (
        echo.
        echo [OK] 安装完成。请重开一个终端让 PATH 生效, 然后运行 install-copilot-api-service.cmd
        goto :eof
    )
)

echo.
echo [WARN] 自动安装失败, 请手动下载:
echo   https://nssm.cc/download
echo 解压后把 win64\nssm.exe 放到 PATH 路径下 (例如 C:\Windows\System32\)
pause
