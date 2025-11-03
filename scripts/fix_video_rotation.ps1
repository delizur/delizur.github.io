<#
fix_video_rotation.ps1

Usage examples:
# Rotate pixels 90° clockwise and write a new file
PS> .\scripts\fix_video_rotation.ps1 -InputPath "assets/Autonomous Robot/Rotary_Encoder_Operation.mp4" -Action transpose -Direction cw

# Clear rotation metadata (keep pixels) and write a new file
PS> .\scripts\fix_video_rotation.ps1 -InputPath "assets/Autonomous Robot/Rotary_Encoder_Operation.mp4" -Action nometa

# Dry-run (prints ffmpeg command without running)
PS> .\scripts\fix_video_rotation.ps1 -InputPath "assets/Autonomous Robot/Rotary_Encoder_Operation.mp4" -Action transpose -Direction cw -DryRun

Note: This script requires ffmpeg to be installed and available on PATH.
#>
param(
    [Parameter(Mandatory=$false)]
    [string]$InputPath = "assets/Autonomous Robot/Rotary_Encoder_Operation.mp4",

    [Parameter(Mandatory=$false)]
    [ValidateSet('transpose','nometa')]
    [string]$Action = 'nometa',

    [Parameter(Mandatory=$false)]
    [ValidateSet('cw','ccw')]
    [string]$Direction = 'cw',

    [switch]$DryRun
)

function Test-FFmpeg {
    try {
        $p = Get-Command ffmpeg -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-Path $InputPath)) {
    Write-Error "Input file not found: $InputPath"
    exit 2
}

if (-not (Test-FFmpeg)) {
    Write-Error "ffmpeg not found on PATH. Install ffmpeg and ensure it's available in your PATH. See https://ffmpeg.org/"
    exit 3
}

$fullIn = Resolve-Path -LiteralPath $InputPath
$dir = Split-Path $fullIn -Parent
$base = [System.IO.Path]::GetFileNameWithoutExtension($fullIn)
$ext = [System.IO.Path]::GetExtension($fullIn)

if ($Action -eq 'transpose') {
    $transposeVal = if ($Direction -eq 'cw') { '1' } else { '2' }
    $out = Join-Path $dir ("${base}_rotated${ext}")
    $cmd = "ffmpeg -i `"$fullIn`" -vf \"transpose=${transposeVal}\" -c:a copy `"$out`""
} else {
    # nometa
    $out = Join-Path $dir ("${base}_nometa${ext}")
    $cmd = "ffmpeg -i `"$fullIn`" -c copy -metadata:s:v:0 rotate=0 `"$out`""
}

Write-Host "Input: $fullIn"
Write-Host "Output: $out"
Write-Host "Action: $Action" -NoNewline
if ($Action -eq 'transpose') { Write-Host " (direction: $Direction)" }
Write-Host ""

if ($DryRun) {
    Write-Host "Dry-run. Command would be:`n$cmd" -ForegroundColor Yellow
    exit 0
}

Write-Host "Running ffmpeg..." -ForegroundColor Cyan
$proc = Start-Process -FilePath ffmpeg -ArgumentList "-i", "$fullIn", @(if ($Action -eq 'transpose') { '-vf', "transpose=${transposeVal}" } else { '-c', 'copy', '-metadata:s:v:0', 'rotate=0' }) -NoNewWindow -Wait -PassThru

if ($proc.ExitCode -eq 0) {
    Write-Host "ffmpeg finished successfully. Output written to: $out" -ForegroundColor Green
    Write-Host "If you're happy with the result, you can replace the original file or update the HTML to point to the new file." -ForegroundColor Gray
} else {
    Write-Error "ffmpeg exited with code $($proc.ExitCode). Check ffmpeg output above for details."
}
