@echo off
echo ================================================
echo GitHub Copilot API Server
echo ================================================
echo.

if not exist node_modules (
    echo Installing dependencies...
    bun install
    echo.
)

echo Starting server...
echo.

bun run dev

pause
