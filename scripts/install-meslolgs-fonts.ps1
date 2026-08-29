param(
    [string]$SourceDirectory,
    [string]$TestJsoncPath,
    [switch]$Check,
    [switch]$ConfigureTerminal
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$fontDirectory = if ($env:LOCALAPPDATA) {
    Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
}
else {
    ''
}
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

function Get-JsoncStringEnd {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [int]$Start
    )

    for ($index = $Start + 1; $index -lt $Text.Length; $index++) {
        if ($Text[$index] -eq '\') {
            $index++
            continue
        }

        if ($Text[$index] -eq '"') {
            return $index + 1
        }
    }

    throw "Unterminated JSONC string at offset $Start."
}

function Get-JsoncTriviaEnd {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [int]$Start
    )

    $index = $Start

    while ($index -lt $Text.Length) {
        if ([char]::IsWhiteSpace($Text[$index])) {
            $index++
            continue
        }

        if ($index + 1 -lt $Text.Length -and $Text.Substring($index, 2) -eq '//') {
            $newline = $Text.IndexOf("`n", $index + 2)
            if ($newline -lt 0) {
                return $Text.Length
            }

            $index = $newline + 1
            continue
        }

        if ($index + 1 -lt $Text.Length -and $Text.Substring($index, 2) -eq '/*') {
            $commentEnd = $Text.IndexOf('*/', $index + 2)
            if ($commentEnd -lt 0) {
                throw "Unterminated JSONC comment at offset $index."
            }

            $index = $commentEnd + 2
            continue
        }

        break
    }

    return $index
}

function Get-JsoncContainerEnd {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [int]$Start
    )

    $open = $Text[$Start]
    $close = if ($open -eq '{') { '}' } elseif ($open -eq '[') { ']' } else {
        throw "Expected a JSONC container at offset $Start."
    }
    $depth = 1
    $index = $Start + 1

    while ($index -lt $Text.Length) {
        if ($Text[$index] -eq '"') {
            $index = Get-JsoncStringEnd -Text $Text -Start $index
            continue
        }

        if ($index + 1 -lt $Text.Length -and $Text.Substring($index, 2) -eq '//') {
            $index = Get-JsoncTriviaEnd -Text $Text -Start $index
            continue
        }

        if ($index + 1 -lt $Text.Length -and $Text.Substring($index, 2) -eq '/*') {
            $index = Get-JsoncTriviaEnd -Text $Text -Start $index
            continue
        }

        if ($Text[$index] -eq $open) {
            $depth++
        }
        elseif ($Text[$index] -eq $close) {
            $depth--
            if ($depth -eq 0) {
                return $index + 1
            }
        }

        $index++
    }

    throw "Unterminated JSONC container at offset $Start."
}

function Find-JsoncProperty {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [int]$ObjectStart,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($Text[$ObjectStart] -ne '{') {
        throw "Expected a JSONC object at offset $ObjectStart."
    }

    $objectEnd = Get-JsoncContainerEnd -Text $Text -Start $ObjectStart
    $index = $ObjectStart + 1
    $depth = 0

    while ($index -lt $objectEnd - 1) {
        if ($Text[$index] -eq '"') {
            $stringStart = $index
            $stringEnd = Get-JsoncStringEnd -Text $Text -Start $index
            $afterString = Get-JsoncTriviaEnd -Text $Text -Start $stringEnd

            if ($depth -eq 0 -and $afterString -lt $objectEnd -and $Text[$afterString] -eq ':' -and
                $Text.Substring($stringStart, $stringEnd - $stringStart) -eq ('"' + $Name + '"')) {
                $valueStart = Get-JsoncTriviaEnd -Text $Text -Start ($afterString + 1)
                if ($Text[$valueStart] -eq '{' -or $Text[$valueStart] -eq '[') {
                    $valueEnd = Get-JsoncContainerEnd -Text $Text -Start $valueStart
                }
                elseif ($Text[$valueStart] -eq '"') {
                    $valueEnd = Get-JsoncStringEnd -Text $Text -Start $valueStart
                }
                else {
                    $valueEnd = $valueStart
                    while ($valueEnd -lt $objectEnd -and $Text[$valueEnd] -ne ',' -and $Text[$valueEnd] -ne '}') {
                        $valueEnd++
                    }
                }

                return [pscustomobject]@{
                    ValueStart = $valueStart
                    ValueEnd = $valueEnd
                    ObjectEnd = $objectEnd
                }
            }

            $index = $stringEnd
            continue
        }

        if ($index + 1 -lt $objectEnd -and
            ($Text.Substring($index, 2) -eq '//' -or $Text.Substring($index, 2) -eq '/*')) {
            $index = Get-JsoncTriviaEnd -Text $Text -Start $index
            continue
        }

        if ($Text[$index] -eq '{' -or $Text[$index] -eq '[') {
            $depth++
        }
        elseif ($Text[$index] -eq '}' -or $Text[$index] -eq ']') {
            $depth--
        }

        $index++
    }

    return $null
}

function Add-JsoncObjectProperty {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [int]$ObjectStart,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$JsonValue
    )

    $lineStart = $Text.LastIndexOf("`n", $ObjectStart)
    $lineStart = if ($lineStart -lt 0) { 0 } else { $lineStart + 1 }
    $indent = $Text.Substring($lineStart, $ObjectStart - $lineStart) + '    '
    $addition = "`n$indent`"$Name`": $JsonValue,"
    return $Text.Insert($ObjectStart + 1, $addition)
}

function Ensure-JsoncObjectProperty {
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [int]$ObjectStart,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $property = Find-JsoncProperty -Text $Text -ObjectStart $ObjectStart -Name $Name
    if ($null -ne $property) {
        if ($Text[$property.ValueStart] -ne '{') {
            throw "JSONC property '$Name' is not an object."
        }

        return $Text
    }

    return Add-JsoncObjectProperty -Text $Text -ObjectStart $ObjectStart -Name $Name -JsonValue '{}'
}

function Set-JsoncTerminalFont {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $rootStart = Get-JsoncTriviaEnd -Text $Text -Start 0
    if ($rootStart -ge $Text.Length -or $Text[$rootStart] -ne '{') {
        throw 'Windows Terminal settings do not contain a JSONC root object.'
    }

    $Text = Ensure-JsoncObjectProperty -Text $Text -ObjectStart $rootStart -Name 'profiles'
    $profiles = Find-JsoncProperty -Text $Text -ObjectStart $rootStart -Name 'profiles'
    $Text = Ensure-JsoncObjectProperty -Text $Text -ObjectStart $profiles.ValueStart -Name 'defaults'
    $profiles = Find-JsoncProperty -Text $Text -ObjectStart $rootStart -Name 'profiles'
    $defaults = Find-JsoncProperty -Text $Text -ObjectStart $profiles.ValueStart -Name 'defaults'
    $Text = Ensure-JsoncObjectProperty -Text $Text -ObjectStart $defaults.ValueStart -Name 'font'
    $profiles = Find-JsoncProperty -Text $Text -ObjectStart $rootStart -Name 'profiles'
    $defaults = Find-JsoncProperty -Text $Text -ObjectStart $profiles.ValueStart -Name 'defaults'
    $font = Find-JsoncProperty -Text $Text -ObjectStart $defaults.ValueStart -Name 'font'
    $face = Find-JsoncProperty -Text $Text -ObjectStart $font.ValueStart -Name 'face'

    if ($null -eq $face) {
        return Add-JsoncObjectProperty -Text $Text -ObjectStart $font.ValueStart -Name 'face' -JsonValue '"MesloLGS NF"'
    }

    return $Text.Remove($face.ValueStart, $face.ValueEnd - $face.ValueStart).Insert($face.ValueStart, '"MesloLGS NF"')
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
            $original = [System.IO.File]::ReadAllText($settingsPath)
            $updated = Set-JsoncTerminalFont -Text $original

            if ($updated -ceq $original) {
                Write-Host "[OK] Windows Terminal already uses MesloLGS NF"
                continue
            }

            $backupPath = "$settingsPath.before-meslolgs.bak"
            if (-not (Test-Path $backupPath)) {
                Copy-Item -LiteralPath $settingsPath -Destination $backupPath
            }

            $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
            $temporaryPath = "$settingsPath.dotfiles.tmp"
            [System.IO.File]::WriteAllText($temporaryPath, $updated, $utf8WithoutBom)
            Move-Item -LiteralPath $temporaryPath -Destination $settingsPath -Force

            Write-Host "[OK] Windows Terminal now uses MesloLGS NF"

            $rootStart = Get-JsoncTriviaEnd -Text $updated -Start 0
            $profiles = Find-JsoncProperty -Text $updated -ObjectStart $rootStart -Name 'profiles'
            $profileList = Find-JsoncProperty -Text $updated -ObjectStart $profiles.ValueStart -Name 'list'
            if ($null -ne $profileList) {
                $listText = $updated.Substring($profileList.ValueStart, $profileList.ValueEnd - $profileList.ValueStart)
                if ($listText -match '"font"\s*:\s*\{[^}]*"face"\s*:') {
                    Write-Warning 'One or more profiles override the default font; remove that profile-level font.face to inherit MesloLGS NF.'
                }
            }
        }
        catch {
            Write-Warning "Could not update Windows Terminal settings at '${settingsPath}': $($_.Exception.Message)"
        }
    }
}

if ($TestJsoncPath) {
    $testInput = [System.IO.File]::ReadAllText($TestJsoncPath)
    Write-Output (Set-JsoncTerminalFont -Text $testInput) -NoEnumerate
    exit 0
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
