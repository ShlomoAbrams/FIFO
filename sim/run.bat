@echo off
REM ==============================================================================
REM Windows Batch Runner (run.bat)
REM Executes automated UVM test runner without PowerShell policy blocks
REM ==============================================================================

setlocal

set TEST_NAME=%1
if "%TEST_NAME%"=="" set TEST_NAME=all

set WCLK_HALF=%2
if "%WCLK_HALF%"=="" set WCLK_HALF=5

set RCLK_HALF=%3
if "%RCLK_HALF%"=="" set RCLK_HALF=7

echo Launching Async FIFO UVM Automated Verification Suite...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$TestName='%TEST_NAME%'; $Wclk=%WCLK_HALF%; $Rclk=%RCLK_HALF%; Get-Content '%~dp0run.ps1' | Out-String | Invoke-Expression"

endlocal
