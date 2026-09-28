<#
.SYNOPSIS
    Mirror selected game folders from a remote root onto a local root.

.DESCRIPTION
    For each game name, the local folder must already exist. When the same
    folder also exists under the remote root, its contents are mirrored onto
    the local folder with robocopy /MIR.

    Several batch files can call this one script with different paths and
    game lists. Pass the list as separate arguments, not as a PowerShell
    expression:

        powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\sync-game-mods.ps1 `
            -RemoteRoot "\\server\share\Games" `
            -LocalRoot "E:\Games" `
            -Exclude "*.tmp,*.log" `
            -Games "Scrap Mechanic,No Man's Sky" `
            -RoboArgs "/MIR /FFT /XJ"

    -Games, -Exclude, and -ExcludeDir are comma-separated lists. The
    script splits each one into an array. Trailing slashes on the two
    root paths are removed. -RoboArgs is the switch list. /XF and /XD
    are added from -Exclude and -ExcludeDir.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $RemoteRoot,

    [Parameter(Mandatory = $true)]
    [string] $LocalRoot,

    [Parameter(Mandatory = $true)]
    [string] $Games,

    [string] $Exclude,

    [string] $ExcludeDir,

    [string] $RoboArgs,

    [string] $Caller,

    [string] $LogFile
)

$ErrorActionPreference = 'Stop'

function Get-NormalizedRoot {
    param([Parameter(Mandatory = $true)][string] $Path)

    $trimmed = $Path.Trim().Trim('"')
    while ($trimmed.Length -gt 3 -and ($trimmed.EndsWith('\') -or $trimmed.EndsWith('/'))) {
        $trimmed = $trimmed.Substring(0, $trimmed.Length - 1).TrimEnd()
    }
    if ($trimmed -match '^[A-Za-z]:$') {
        $trimmed = $trimmed + '\'
    }
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        throw 'A root path is empty.'
    }
    return $trimmed
}

function Test-DirectoryLiteral {
    param([Parameter(Mandatory = $true)][string] $Path)
    return [System.IO.Directory]::Exists($Path)
}

function Split-ConfigList {
    param([string] $Text)
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }
    return @($Text.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
}

function Split-RoboArgs {
    param([string] $Text)
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }
    return @($Text -split '\s+' | Where-Object { $_ -ne '' })
}

function Write-Log {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string] $Message)
    Add-Content -LiteralPath $script:LogFile -Value $Message -Encoding UTF8
}

function Invoke-GameMirror {
    param(
        [Parameter(Mandatory = $true)][string] $LocalGame,
        [Parameter(Mandatory = $true)][string] $RemoteGame,
        [Parameter(Mandatory = $true)][string] $Name
    )

    Write-Host "[SYNC] $Name"
    Write-Host "       $RemoteGame"
    Write-Host "       -> $LocalGame"
    Write-Log "----- $Name -----"
    Write-Log $RemoteGame
    Write-Log $LocalGame

    $roboArgs = @(
        $RemoteGame,
        $LocalGame
    ) + @($script:RoboSwitches)

    if ($script:ExcludePatterns.Count -gt 0) {
        $roboArgs += '/XF'
        $roboArgs += $script:ExcludePatterns
    }
    if ($script:ExcludeDirectories.Count -gt 0) {
        $roboArgs += '/XD'
        $roboArgs += $script:ExcludeDirectories
    }

    $output = @(& robocopy.exe @roboArgs 2>&1 | ForEach-Object { "$_" })
    $rc = $LASTEXITCODE
    if ($output.Count -gt 0) {
        $output | Add-Content -LiteralPath $script:LogFile -Encoding UTF8
    }

    if ($rc -ge 8) {
        Write-Host "[FAIL] $Name  robocopy exit $rc"
        Write-Log "[FAIL] $Name robocopy exit $rc"
        return $rc
    }

    Write-Host "[OK]   $Name"
    Write-Log "[OK] $Name robocopy exit $rc"
    return $rc
}

if ($PSBoundParameters.ContainsKey('Exclude')) {
    $script:ExcludePatterns = @(Split-ConfigList $Exclude)
}
else {
    $script:ExcludePatterns = @(
        '*.tmp', '*.temp', '*.log', '*.bak', '*.old',
        '*.dmp', '*.partial', 'Thumbs.db', 'desktop.ini'
    )
}
$script:ExcludeDirectories = @(Split-ConfigList $ExcludeDir)

if ($PSBoundParameters.ContainsKey('RoboArgs')) {
    $script:RoboSwitches = @(Split-RoboArgs $RoboArgs)
}
else {
    $script:RoboSwitches = @(
        '/MIR', '/COPY:DAT', '/DCOPY:DAT', '/FFT', '/XJ',
        '/MT:8', '/R:2', '/W:3', '/NP', '/NDL', '/NFL'
    )
}

$script:GameNames = @(Split-ConfigList $Games)
if ($script:GameNames.Count -eq 0) {
    Write-Host '[ERROR] No game names were given. Add names to the GAMES variable, separated by commas.'
    exit 1
}

if (-not (Get-Command robocopy.exe -ErrorAction SilentlyContinue)) {
    Write-Host '[ERROR] robocopy.exe was not found.'
    exit 1
}

try {
    $RemoteRoot = Get-NormalizedRoot $RemoteRoot
    $LocalRoot = Get-NormalizedRoot $LocalRoot
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}

if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
    $LogFile = $LogFile.Trim().Trim('"')
}
elseif (-not [string]::IsNullOrWhiteSpace($Caller)) {
    $callerPath = $Caller.Trim().Trim('"')
    $LogFile = [System.IO.Path]::ChangeExtension($callerPath, '.log')
}
else {
    $LogFile = Join-Path -Path $PSScriptRoot -ChildPath 'sync-game-mods.log'
}

$logDir = Split-Path -Parent $LogFile
if ($logDir -and -not (Test-DirectoryLiteral $logDir)) {
    Write-Host "[ERROR] Log folder not found: $logDir"
    exit 1
}

$header = @(
    "Game mod sync $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Remote: $RemoteRoot"
    "Local:  $LocalRoot"
    ''
)
Set-Content -LiteralPath $LogFile -Value $header -Encoding UTF8

Write-Host '=========================================='
Write-Host '         GAME MOD SYNC'
Write-Host '=========================================='
Write-Host "Remote: $RemoteRoot"
Write-Host "Local:  $LocalRoot"
Write-Host "Log:    $LogFile"
Write-Host '=========================================='
Write-Host ''

if (-not (Test-DirectoryLiteral $RemoteRoot)) {
    $message = "[ERROR] Remote root not found or not reachable: $RemoteRoot"
    Write-Host $message
    Write-Log $message
    exit 1
}
if (-not (Test-DirectoryLiteral $LocalRoot)) {
    $message = "[ERROR] Local root not found: $LocalRoot"
    Write-Host $message
    Write-Log $message
    exit 1
}

$synced = 0
$skipped = 0
$failed = 0

foreach ($game in $script:GameNames) {
    $name = if ($null -eq $game) { '' } else { $game.Trim() }
    if ([string]::IsNullOrWhiteSpace($name)) {
        continue
    }

    if ($name -match '[\\/]' -or $name -eq '.' -or $name -eq '..') {
        Write-Host "[SKIP] Not a single folder name: $name"
        Write-Log "[SKIP] Not a single folder name: $name"
        $skipped++
        continue
    }

    $localGame = Join-Path -Path $LocalRoot -ChildPath $name
    $remoteGame = Join-Path -Path $RemoteRoot -ChildPath $name

    if (-not (Test-DirectoryLiteral $localGame)) {
        Write-Host "[SKIP] Not installed locally: $name"
        Write-Log "[SKIP] Not installed locally: $name"
        $skipped++
        continue
    }

    if (-not (Test-DirectoryLiteral $remoteGame)) {
        Write-Host "[SKIP] Not on remote: $name"
        Write-Log "[SKIP] Not on remote: $name"
        $skipped++
        continue
    }

    $rc = Invoke-GameMirror -LocalGame $localGame -RemoteGame $remoteGame -Name $name
    if ($rc -ge 8) {
        $failed++
    }
    else {
        $synced++
    }
}

Write-Host ''
Write-Host '=========================================='
Write-Host "Synced:  $synced"
Write-Host "Skipped: $skipped"
Write-Host "Failed:  $failed"
Write-Host '=========================================='
Write-Log ''
Write-Log "Synced=$synced Skipped=$skipped Failed=$failed"

if ($failed -gt 0) {
    exit 1
}
exit 0
