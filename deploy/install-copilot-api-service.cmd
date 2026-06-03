@echo off
REM ============================================================
REM  把 copilot-api 注册成 Windows 服务 (开机自启 + 崩溃重启)
REM
REM  前置条件:
REM    1. 已运行 deploy\install-nssm.cmd 装好 nssm
REM    2. 已至少手动跑过一次 deploy\start-all.cmd 完成 GitHub device code 登录
REM       (token 缓存到 %LOCALAPPDATA%\copilot-api\, 服务才能无人值守启动)
REM    3. deploy\.env 已配置 PROXY_AUTH_TOKEN
REM
REM  需要管理员权限
REM ============================================================
setlocal EnableDelayedExpansion

REM --- 检查管理员 ---
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 需要以管理员身份运行此脚本。
    echo 右键 -^> 以管理员身份运行
    pause
    exit /b 1
)

REM --- 检查 nssm ---
where nssm >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] nssm 未安装, 请先运行 deploy\install-nssm.cmd
    pause
    exit /b 1
)

REM --- 检查 bun ---
where bun >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] bun 未安装, 请先安装: https://bun.com/docs/installation#windows
    pause
    exit /b 1
)

REM --- 解析路径 ---
set "PROJECT_DIR=%~dp0.."
pushd "%PROJECT_DIR%"
set "PROJECT_DIR=%CD%"
popd

set "ENV_FILE=%~dp0.env"
if not exist "%ENV_FILE%" (
    echo [ERROR] 找不到 %ENV_FILE%
    pause
    exit /b 1
)

REM --- 加载 .env ---
for /f "usebackq tokens=1,2 delims==" %%A in ("%ENV_FILE%") do (
    set "%%A=%%B"
)

if "%COPILOT_API_PORT%"=="" set "COPILOT_API_PORT=4141"

if "%PROXY_AUTH_TOKEN%"=="" (
    echo [WARN] PROXY_AUTH_TOKEN 未设置 - 服务将无鉴权运行 ^(任何人能调用^)
    echo 强烈建议先在 deploy\.env 设置 PROXY_AUTH_TOKEN, 然后重跑此脚本
    set /p "CONTINUE=确认继续? (y/N): "
    if /i not "!CONTINUE!"=="y" exit /b 1
)

REM --- 查 bun 完整路径 (nssm 需要绝对路径) ---
for /f "delims=" %%I in ('where bun') do set "BUN_PATH=%%I" & goto :found_bun
:found_bun
echo [INFO] Bun: %BUN_PATH%
echo [INFO] 项目目录: %PROJECT_DIR%
echo [INFO] 端口: %COPILOT_API_PORT%

REM --- 服务名 ---
set "SVC_NAME=copilot-api"
set "LOG_DIR=%PROJECT_DIR%\deploy\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM --- 如果已存在, 先卸载 ---
sc query %SVC_NAME% >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [INFO] 服务 %SVC_NAME% 已存在, 先卸载...
    nssm stop %SVC_NAME% confirm >nul 2>&1
    nssm remove %SVC_NAME% confirm
)

REM --- 安装服务 ---
echo [INFO] 安装服务 %SVC_NAME%...
nssm install %SVC_NAME% "%BUN_PATH%" run "%PROJECT_DIR%\src\main.ts" start --port %COPILOT_API_PORT%
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] nssm install 失败
    pause
    exit /b 1
)

REM --- 配置服务参数 ---
nssm set %SVC_NAME% AppDirectory "%PROJECT_DIR%"
nssm set %SVC_NAME% DisplayName "Copilot API Proxy"
nssm set %SVC_NAME% Description "GitHub Copilot -> OpenAI/Anthropic compatible proxy"
nssm set %SVC_NAME% Start SERVICE_AUTO_START

REM --- 环境变量 ---
nssm set %SVC_NAME% AppEnvironmentExtra ^
    NODE_ENV=production ^
    PROXY_AUTH_TOKEN=%PROXY_AUTH_TOKEN%

REM --- 日志输出 ---
nssm set %SVC_NAME% AppStdout "%LOG_DIR%\copilot-api.out.log"
nssm set %SVC_NAME% AppStderr "%LOG_DIR%\copilot-api.err.log"
nssm set %SVC_NAME% AppRotateFiles 1
nssm set %SVC_NAME% AppRotateBytes 10485760

REM --- 崩溃自动重启 ---
nssm set %SVC_NAME% AppExit Default Restart
nssm set %SVC_NAME% AppRestartDelay 3000

REM --- 启动 ---
echo [INFO] 启动服务...
nssm start %SVC_NAME%
timeout /t 3 /nobreak >nul

echo.
echo ================================================
echo  [OK] copilot-api 服务已安装并启动
echo ================================================
echo.
echo 管理命令:
echo   net start  copilot-api          启动
echo   net stop   copilot-api          停止
echo   nssm restart copilot-api        重启
echo   nssm edit  copilot-api          图形化编辑配置
echo   nssm remove copilot-api confirm 卸载
echo.
echo 日志路径:
echo   %LOG_DIR%\copilot-api.out.log
echo   %LOG_DIR%\copilot-api.err.log
echo.
echo 验证:
echo   curl http://localhost:%COPILOT_API_PORT%/
echo.

endlocal
pause
