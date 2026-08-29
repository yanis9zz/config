$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not ('DotfilesWindowState' -as [type])) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class DotfilesWindowState
{
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);

    [DllImport("user32.dll")]
    public static extern bool IsZoomed(IntPtr window);

    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr window, int command);
}
'@
}

$window = [DotfilesWindowState]::GetForegroundWindow()
[uint32]$processId = 0
[void][DotfilesWindowState]::GetWindowThreadProcessId($window, [ref]$processId)

try {
    $foregroundProcess = Get-Process -Id $processId -ErrorAction Stop
}
catch {
    exit 1
}

if ($foregroundProcess.ProcessName -eq 'WindowsTerminal' -and
    -not [DotfilesWindowState]::IsZoomed($window)) {
    [void][DotfilesWindowState]::ShowWindowAsync($window, 3)
}
