<#
Rotate or auto-orient images for the site.
Usage examples (PowerShell):
  # Auto-orient (uses EXIF orientation to rotate pixels upright):
  .\rotate_image.ps1 -InPath "assets/BIoT/brewbox-circuit.jpg" -OutPath "assets/BIoT/brewbox-circuit.rotated.jpg" -Mode auto

  # Rotate 90 degrees clockwise:
  .\rotate_image.ps1 -InPath "assets/BIoT/brewbox-circuit.jpg" -OutPath "assets/BIoT/brewbox-circuit.rotated.jpg" -Mode 90

  # Rotate 90 degrees counter-clockwise:
  .\rotate_image.ps1 -InPath "assets/BIoT/brewbox-circuit.jpg" -OutPath "assets/BIoT/brewbox-circuit.rotated.jpg" -Mode 270

  # Rotate 180 degrees:
  .\rotate_image.ps1 -InPath "in.jpg" -OutPath "out.jpg" -Mode 180

Notes:
- This script prefers ImageMagick (magick). If not present and the input is JPEG, it will try jpegtran for lossless rotation/auto-orient.
- Install ImageMagick (https://imagemagick.org) or jpegtran (part of libjpeg or available via some packages) before using.
- After creating the rotated file, update the <img> source in your HTML to point to the rotated filename.
#>
param(
  [Parameter(Mandatory=$true)] [string] $InPath,
  [Parameter(Mandatory=$true)] [string] $OutPath,
  [ValidateSet('auto','90','180','270')] [string] $Mode = 'auto'
)

function CommandExists([string]$cmd){
  try{ $null = Get-Command $cmd -ErrorAction Stop; return $true } catch { return $false }
}

$inFull = Resolve-Path -LiteralPath $InPath -ErrorAction Stop
$outFull = Resolve-Path -LiteralPath (Split-Path -Parent $OutPath) -ErrorAction SilentlyContinue
if(-not $outFull){
  # Ensure output folder exists
  $outDir = Split-Path -Parent $OutPath
  if($outDir -and -not (Test-Path $outDir)){ New-Item -ItemType Directory -Path $outDir | Out-Null }
}

if(CommandExists 'magick'){
  Write-Host "Using ImageMagick (magick) to process the image..."
  switch($Mode){
    'auto' {
      # Use convert with -auto-orient to write an explicit output file
      $args = @('convert', $InPath, '-auto-orient', $OutPath)
    }
    '90' {
      $args = @('convert', $InPath, '-rotate', '90', $OutPath)
    }
    '270' {
      $args = @('convert', $InPath, '-rotate', '270', $OutPath)
    }
    '180' {
      $args = @('convert', $InPath, '-rotate', '180', $OutPath)
    }
  }
  Write-Host "magick" ($args -join ' ')
  # Start-Process accepts an array for ArgumentList; pass arguments directly
  $proc = Start-Process -FilePath 'magick' -ArgumentList $args -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
  if($proc -and $proc.ExitCode -eq 0){ Write-Host "Done: $OutPath"; exit 0 } else { Write-Warning "magick reported exit code $($proc.ExitCode)." }
}

# If magick not present, fallback to jpegtran for JPEGs (lossless rotate) or fallback message
$ext = [IO.Path]::GetExtension($InPath).ToLowerInvariant()
if($ext -in '.jpg','.jpeg'){
  if(CommandExists 'jpegtran'){
    Write-Host "Using jpegtran for lossless rotation (JPEG)."
    switch($Mode){
      'auto' { $args = @('-copy','all','-rotate','0','-outfile',$OutPath,$InPath) }
      '90'   { $args = @('-copy','all','-rotate','90','-outfile',$OutPath,$InPath) }
      '270'  { $args = @('-copy','all','-rotate','270','-outfile',$OutPath,$InPath) }
      '180'  { $args = @('-copy','all','-rotate','180','-outfile',$OutPath,$InPath) }
    }
    Write-Host "jpegtran" ($args -join ' ')
    $proc = Start-Process -FilePath 'jpegtran' -ArgumentList $args -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
    if($proc -and $proc.ExitCode -eq 0){ Write-Host "Done: $OutPath"; exit 0 } else { Write-Warning "jpegtran reported exit code $($proc.ExitCode)." }
  }
}

  # Final fallback: try to use .NET's System.Drawing on Windows (PowerShell 5.x / .NET Framework)
  try{
    if($PSVersionTable.PSVersion.Major -ge 5 -and $env:OS -match 'Windows'){
      Write-Host "Attempting System.Drawing fallback (Windows) to rotate/save image..."
      Add-Type -AssemblyName System.Drawing
      $srcPath = (Resolve-Path -LiteralPath $InPath).Path
      $img = [System.Drawing.Image]::FromFile($srcPath)
      switch($Mode){
        '90'  { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        '270' { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
        '180' { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        default { # 'auto' - try to auto-orient by reading EXIF orientation if present
          try{
            $prop = $img.PropertyItems | Where-Object { $_.Id -eq 0x0112 } 
            if($prop){
              $orientation = $prop.Value[0]
              switch($orientation){
                3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
                6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
                8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
              }
            }
          } catch { }
        }
      }
      $outPathResolved = (Resolve-Path -LiteralPath (Split-Path -Parent $OutPath) -ErrorAction SilentlyContinue)
      if(-not $outPathResolved){ $outDir = Split-Path -Parent $OutPath; if($outDir -and -not (Test-Path $outDir)){ New-Item -ItemType Directory -Path $outDir | Out-Null } }
      $imgFormat = [System.Drawing.Imaging.ImageFormat]::Jpeg
      $img.Save($OutPath, $imgFormat)
      $img.Dispose()
      Write-Host "Done: $OutPath (System.Drawing)"
      exit 0
    }
  } catch {
    Write-Warning "System.Drawing fallback failed: $_"
  }

  Write-Error "No suitable image tool found (magick or jpegtran) and System.Drawing fallback failed. Please install ImageMagick (https://imagemagick.org) or jpegtran and re-run this script."
  exit 2
