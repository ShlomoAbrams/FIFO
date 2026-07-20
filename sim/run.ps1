<#
.SYNOPSIS
    Automated Headless Test Runner for Async FIFO UVM Verification Environment.
.DESCRIPTION
    Launches ModelSim headlessly or in GUI mode, sweeps test scenarios, passes dynamic clock arguments,
    parses transcript logs for errors, and reports overall verification status.
.PARAMETER TestName
    Target test to run: 'fifo_test', 'fifo_reset_recovery_test', or 'all' (default).
.PARAMETER Wclk
    Write clock half-period in nanoseconds (default: 5).
.PARAMETER Rclk
    Read clock half-period in nanoseconds (default: 7).
.PARAMETER Gui
    Launch in interactive GUI mode instead of batch mode.
.PARAMETER Clean
    Clean build artifacts and exit.
.EXAMPLE
    .\run.ps1 -TestName all
    .\run.ps1 -TestName fifo_reset_recovery_test -Wclk 2 -Rclk 10
#>

param(
    [string]$TestName = "all",
    [int]$Wclk = 5,
    [int]$Rclk = 7,
    [switch]$Gui,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

# STEP 1: LOCATE MODELSIM EXECUTABLE
$VsimPath = Get-Command vsim -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
if (-not $VsimPath) {
    $Candidates = @(
        "C:\MentorGraphics\MODELSIM\win64\vsim.exe",
        "C:\modeltech64_*\win64\vsim.exe",
        "C:\questasim64_*\win64\vsim.exe"
    )
    foreach ($cand in $Candidates) {
        $Found = Get-Item $cand -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($Found) {
            $VsimPath = $Found.FullName
            break
        }
    }
}

if (-not $VsimPath) {
    Write-Error "Could not locate vsim.exe! Please add ModelSim/Questa bin folder to system PATH."
    exit 1
}

$SimDir = $PSScriptRoot

if ($Clean) {
    Write-Host "Cleaning simulation directory..." -ForegroundColor Yellow
    Set-Location $SimDir
    Remove-Item -Recurse -Force work, covhtmlreport, covhtml, fifo_cov.ucdb, transcript, *.wlf -ErrorAction SilentlyContinue
    Write-Host "Clean completed." -ForegroundColor Green
    exit 0
}

# STEP 2: DETERMINE TESTS TO EXECUTE
$TestsToRun = @()
if ($TestName -eq "all") {
    $TestsToRun = @("fifo_test", "fifo_reset_recovery_test")
} else {
    $TestsToRun = @($TestName)
}

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Async FIFO UVM Automated Verification Suite" -ForegroundColor Cyan
Write-Host " ModelSim Path : $VsimPath" -ForegroundColor Gray
Write-Host " Write Clock   : Half-Period = ${Wclk}ns (Freq = $([math]::Round(500/$Wclk, 1)) MHz)" -ForegroundColor Gray
Write-Host " Read Clock    : Half-Period = ${Rclk}ns (Freq = $([math]::Round(500/$Rclk, 1)) MHz)" -ForegroundColor Gray
Write-Host "========================================================" -ForegroundColor Cyan

$Results = @()
$OverallSuccess = $true

Set-Location $SimDir

foreach ($t in $TestsToRun) {
    Write-Host "`nRunning Test: $t..." -ForegroundColor Yellow

    if (Test-Path "transcript") { Remove-Item "transcript" -Force }

    $ModeFlag = if ($Gui) { "" } else { "-c" }
    $DoCommand = "set TESTNAME $t; set WCLK_HALF $Wclk; set RCLK_HALF $Rclk; do run.do"
    if (-not $Gui) {
        $DoCommand += "; quit -f"
    }

    $Process = Start-Process -FilePath $VsimPath -ArgumentList "$ModeFlag -do `"$DoCommand`"" -NoNewWindow -PassThru -Wait

    # STEP 3: AUTOMATICALLY PARSE LOG TRANSCRIPT FOR ERRORS
    $Passed = $false
    $UvmErrors = 0
    $UvmFatals = 0
    $SvaFailures = 0

    if (Test-Path "transcript") {
        $LogLines = Get-Content "transcript"

        $UvmErrorMatches = $LogLines | Select-String -Pattern 'UVM_ERROR\s*:\s*(\d+)'
        if ($UvmErrorMatches) {
            $UvmErrors = [int]($UvmErrorMatches[-1].Matches.Groups[1].Value)
        }

        $UvmFatalMatches = $LogLines | Select-String -Pattern 'UVM_FATAL\s*:\s*(\d+)'
        if ($UvmFatalMatches) {
            $UvmFatals = [int]($UvmFatalMatches[-1].Matches.Groups[1].Value)
        }

        $SvaMatches = $LogLines | Select-String -Pattern 'Assertion failure'
        if ($SvaMatches) {
            $SvaFailures = $SvaMatches.Count
        }

        $FinishedMatch = $LogLines | Select-String -Pattern 'finished successfully|Simulation Finished'
        if ($FinishedMatch -and ($UvmErrors -eq 0) -and ($UvmFatals -eq 0) -and ($SvaFailures -eq 0)) {
            $Passed = $true
        }
    }

    if ($Passed) {
        Write-Host "  -> RESULT: PASS (0 Errors, 0 SVA Failures)" -ForegroundColor Green
        $Results += [PSCustomObject]@{
            TestName = $t
            Status   = "PASS"
            Errors   = $UvmErrors
            Fatals   = $UvmFatals
            SVA_Fail = $SvaFailures
        }
    } else {
        Write-Host "  -> RESULT: FAIL (UVM Errors: $UvmErrors, Fatals: $UvmFatals, SVA Failures: $SvaFailures)" -ForegroundColor Red
        $OverallSuccess = $false
        $Results += [PSCustomObject]@{
            TestName = $t
            Status   = "FAIL"
            Errors   = $UvmErrors
            Fatals   = $UvmFatals
            SVA_Fail = $SvaFailures
        }
    }
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
$Results | Format-Table -AutoSize

if ($OverallSuccess) {
    Write-Host "SUCCESS: All verification tests passed cleanly!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "FAILURE: Verification test suite failed!" -ForegroundColor Red
    exit 1
}
