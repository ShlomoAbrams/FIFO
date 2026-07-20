@echo off
REM ==============================================================================
REM Windows Batch Runner (run.bat)
REM Executes automated UVM test runner quietly with full parameter passing
REM Usage: run.bat [TestName] [Wclk] [Rclk] [DataWidth] [AddrWidth]
REM ==============================================================================

setlocal

set TEST_NAME=%1
if "%TEST_NAME%"=="" set TEST_NAME=all

set WCLK_HALF=%2
if "%WCLK_HALF%"=="" set WCLK_HALF=5

set RCLK_HALF=%3
if "%RCLK_HALF%"=="" set RCLK_HALF=7

set DATA_WIDTH=%4
if "%DATA_WIDTH%"=="" set DATA_WIDTH=8

set ADDR_WIDTH=%5
if "%ADDR_WIDTH%"=="" set ADDR_WIDTH=4

powershell -NoProfile -ExecutionPolicy Bypass -Command "$t='%TEST_NAME%'; $w=[int]%WCLK_HALF%; $r=[int]%RCLK_HALF%; $dw=[int]%DATA_WIDTH%; $aw=[int]%ADDR_WIDTH%; $s = Get-Content '%~dp0run.ps1' -Raw; & ([scriptblock]::Create($s)) -TestName $t -Wclk $w -Rclk $r -DataWidth $dw -AddrWidth $aw"

endlocal
