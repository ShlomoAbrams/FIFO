<#
.SYNOPSIS
    Automated Quiet Test Runner for Async FIFO UVM Verification Environment.
.DESCRIPTION
    Launches ModelSim headlessly, sweeps test scenarios, passes dynamic clock arguments and
    hardware parameters (DATA_WIDTH, ADDR_WIDTH), parses logs for UVM errors, and displays a clean status table.
.PARAMETER TestName
    Target test to run: 'fifo_test', 'fifo_reset_recovery_test', or 'all' (default).
.PARAMETER Wclk
    Write clock half-period in nanoseconds (default: 5).
.PARAMETER Rclk
    Read clock half-period in nanoseconds (default: 7).
.PARAMETER DataWidth
    FIFO Data Width in bits (default: 8).
.PARAMETER AddrWidth
    FIFO Address Width in bits (default: 4 -> Depth = 16).
.PARAMETER Verbose
    Show raw ModelSim output instead of hiding compilation logs.
.PARAMETER Clean
    Clean build artifacts and exit.
#>

param(
    [string]$TestName = "all",
    [int]$Wclk = 5,
    [int]$Rclk = 7,
    [int]$DataWidth = 8,
    [int]$AddrWidth = 4,
    [switch]$Verbose,
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
    Remove-Item -Recurse -Force work, covhtmlreport, covhtml, fifo_cov.ucdb, transcript, *.wlf, vsim_run.log -ErrorAction SilentlyContinue
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

$FifoDepth = [math]::Pow(2, $AddrWidth)

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Async FIFO UVM Automated Test Suite" -ForegroundColor Cyan
Write-Host " Hardware Config: Data Width = ${DataWidth}-bit | Depth = ${FifoDepth} (${AddrWidth}-bit addr)" -ForegroundColor Gray
Write-Host " Write Clock     : Half-Period = ${Wclk}ns (Freq = $([math]::Round(500/$Wclk, 1)) MHz)" -ForegroundColor Gray
Write-Host " Read Clock      : Half-Period = ${Rclk}ns (Freq = $([math]::Round(500/$Rclk, 1)) MHz)" -ForegroundColor Gray
Write-Host "========================================================" -ForegroundColor Cyan

$Results = @()
$OverallSuccess = $true

Set-Location $SimDir

foreach ($t in $TestsToRun) {
    Write-Host -NoNewline "Running $t... "

    if (Test-Path "transcript") { Remove-Item "transcript" -Force }

    $DoCommand = "set TESTNAME $t; set WCLK_HALF $Wclk; set RCLK_HALF $Rclk; set DATA_WIDTH $DataWidth; set ADDR_WIDTH $AddrWidth; do run.do; quit -f"

    # RUN MODELSIM QUIETLY (Redirect output to vsim_run.log to avoid terminal clutter)
    if ($Verbose) {
        $Process = Start-Process -FilePath $VsimPath -ArgumentList "-c -do `"$DoCommand`"" -NoNewWindow -PassThru -Wait
    } else {
        $Process = Start-Process -FilePath $VsimPath -ArgumentList "-c -do `"$DoCommand`"" -RedirectStandardOutput "vsim_run.log" -RedirectStandardError "vsim_err.log" -WindowStyle Hidden -PassThru -Wait
    }

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
        Write-Host "PASS" -ForegroundColor Green
        $Results += [PSCustomObject]@{
            TestName = $t
            Status   = "PASS"
            Errors   = $UvmErrors
            Fatals   = $UvmFatals
            SVA_Fail = $SvaFailures
        }
    } else {
        Write-Host "FAIL" -ForegroundColor Red
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
