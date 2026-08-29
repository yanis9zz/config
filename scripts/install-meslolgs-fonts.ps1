param(
    [string]$SourceDirectory,
    [switch]$Check,
    [switch]$ConfigureTerminal
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$fontDirectory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$registryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
$fonts = @(
    @{ FileName = 'MesloLGS NF Regular.ttf'; RegistryName = 'MesloLGS NF Regular (TrueType)' },
    @{ FileName = 'MesloLGS NF Bold.ttf'; RegistryName = 'MesloLGS NF Bold (TrueType)' },
    @{ FileName = 'MesloLGS NF Italic.ttf'; RegistryName = 'MesloLGS NF Italic (TrueType)' },
    @{ FileName = 'MesloLGS NF Bold Italic.ttf'; RegistryName = 'MesloLGS NF Bold Italic (TrueType)' }
)

function Test-MesloFontsInstalled {
    if (-not (Test-Path $registryPath)) {
        return $false
    }

    $registry = Get-ItemProperty -Path $registryPath

    foreach ($font in $fonts) {
        $fontPath = Join-Path $fontDirectory $font.FileName
        $registryValue = $registry.PSObject.Properties[$font.RegistryName]

        if (-not (Test-Path $fontPath) -or $null -eq $registryValue) {
            return $false
        }
    }

    return $true
}

function Send-FontChangeNotification {
    if (-not ('FontChangeNotifier' -as [type])) {
        Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class FontChangeNotifier
{
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint message,
        IntPtr wParam,
        IntPtr lParam,
        uint flags,
        uint timeout,
        out IntPtr result);
}
'@
    }

    $result = [IntPtr]::Zero
    [void][FontChangeNotifier]::SendMessageTimeout(
        [IntPtr]0xffff,
        0x001D,
        [IntPtr]::Zero,
        [IntPtr]::Zero,
        0x0002,
        5000,
        [ref]$result
    )
}

function Get-OrAddObjectProperty {
    param(
        [Parameter(Mandatory)]
        [object]$Parent,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $property = $Parent.PSObject.Properties[$Name]

    if ($null -eq $property) {
        $value = [pscustomobject]@{}
        $Parent | Add-Member -MemberType NoteProperty -Name $Name -Value $value
        return $value
    }

    if ($null -eq $property.Value) {
        $property.Value = [pscustomobject]@{}
    }

    return $property.Value
}

function Set-WindowsTerminalFont {
    $packageDirectory = Join-Path $env:LOCALAPPDATA 'Packages'
    $settingsPaths = @(
        if (Test-Path $packageDirectory) {
            Get-ChildItem -Path $packageDirectory -Directory -Filter 'Microsoft.WindowsTerminal*' |
                ForEach-Object { Join-Path $_.FullName 'LocalState\settings.json' }
        }

        Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
    ) | Where-Object { Test-Path $_ } | Sort-Object -Unique

    if (@($settingsPaths).Count -eq 0) {
        Write-Warning 'Windows Terminal settings were not found; select MesloLGS NF manually.'
        return
    }

    foreach ($settingsPath in $settingsPaths) {
        try {
            $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
            $profiles = Get-OrAddObjectProperty -Parent $settings -Name 'profiles'
            $defaults = Get-OrAddObjectProperty -Parent $profiles -Name 'defaults'
            $font = Get-OrAddObjectProperty -Parent $defaults -Name 'font'
            $face = $font.PSObject.Properties['face']

            if ($null -ne $face -and $face.Value -eq 'MesloLGS NF') {
                Write-Host "[OK] Windows Terminal already uses MesloLGS NF"
                continue
            }

            if ($null -eq $face) {
                $font | Add-Member -MemberType NoteProperty -Name 'face' -Value 'MesloLGS NF'
            }
            else {
                $face.Value = 'MesloLGS NF'
            }

            $backupPath = "$settingsPath.before-meslolgs.bak"
            if (-not (Test-Path $backupPath)) {
                Copy-Item -LiteralPath $settingsPath -Destination $backupPath
            }

            $json = $settings | ConvertTo-Json -Depth 100
            $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText(
                $settingsPath,
                $json + [Environment]::NewLine,
                $utf8WithoutBom
            )

            Write-Host "[OK] Windows Terminal now uses MesloLGS NF"
        }
        catch {
            Write-Warning "Could not update Windows Terminal settings at '${settingsPath}': $($_.Exception.Message)"
        }
    }
}

if ($Check) {
    if (Test-MesloFontsInstalled) {
        exit 0
    }

    exit 1
}

if ($ConfigureTerminal) {
    Set-WindowsTerminalFont
    exit 0
}

if (-not $SourceDirectory -or -not (Test-Path $SourceDirectory)) {
    throw 'SourceDirectory must point to the downloaded MesloLGS NF font files.'
}

New-Item -ItemType Directory -Path $fontDirectory -Force | Out-Null
New-Item -Path $registryPath -Force | Out-Null

foreach ($font in $fonts) {
    $source = Join-Path $SourceDirectory $font.FileName
    $destination = Join-Path $fontDirectory $font.FileName

    if (-not (Test-Path $source)) {
        throw "Missing font file: $source"
    }

    Copy-Item -Path $source -Destination $destination -Force
    New-ItemProperty `
        -Path $registryPath `
        -Name $font.RegistryName `
        -Value $destination `
        -PropertyType String `
        -Force | Out-Null
}

if (-not (Test-MesloFontsInstalled)) {
    throw 'MesloLGS NF installation validation failed.'
}

Send-FontChangeNotification
Set-WindowsTerminalFont
