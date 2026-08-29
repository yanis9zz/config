$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptPath = Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'scripts') 'install-meslolgs-fonts.ps1'
$temporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-jsonc-$([guid]::NewGuid()).json"

try {
    $inputJsonc = @'
{
    // This comment and the trailing commas must survive.
    "profiles": {
        "defaults": {
            "font": {
                "face": "Cascadia Mono", // keep this comment
            },
        },
        "list": [
            { "name": "Example", "font": { "face": "Profile override" }, },
        ],
    },
}
'@
    [System.IO.File]::WriteAllText($temporaryPath, $inputJsonc)
    $updated = & $scriptPath -TestJsoncPath $temporaryPath

    if ($updated -notmatch '// This comment' -or $updated -notmatch '// keep this comment') {
        throw 'JSONC comments were not preserved.'
    }
    if ($updated -notmatch '"face": "MesloLGS NF", // keep this comment') {
        throw 'The default font was not replaced in place.'
    }
    if ($updated -notmatch '"Profile override" }, },') {
        throw 'Trailing commas or profile values were changed.'
    }

    [System.IO.File]::WriteAllText($temporaryPath, ($updated -join [Environment]::NewLine))
    $secondPass = & $scriptPath -TestJsoncPath $temporaryPath
    if (($secondPass -join [Environment]::NewLine) -cne ($updated -join [Environment]::NewLine)) {
        throw 'The JSONC update is not idempotent.'
    }

    [System.IO.File]::WriteAllText($temporaryPath, "{`n    // empty settings`n}`n")
    $created = (& $scriptPath -TestJsoncPath $temporaryPath) -join [Environment]::NewLine
    if ($created -notmatch '"profiles"' -or $created -notmatch '"face": "MesloLGS NF"') {
        throw 'Missing profiles/defaults/font objects were not created.'
    }

    Write-Host 'JSONC preservation test passed'
}
finally {
    if (Test-Path $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}
