param(
    [int]$Port = 8000
)

# Simple static file server using HttpListener
# Usage: .\scripts\serve.ps1 -Port 8000

Add-Type -AssemblyName System.Web

$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
    Write-Host "Serving $prefix (Press Ctrl+C to stop)"
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        Start-Job -ScriptBlock {
            param($ctx, $pwd)
            try {
                $request = $ctx.Request
                $response = $ctx.Response
                $localPath = $request.Url.AbsolutePath.TrimStart('/')
                if ([string]::IsNullOrEmpty($localPath)) { $localPath = 'index.html' }

                $filePath = Join-Path $pwd $localPath

                if (Test-Path $filePath) {
                    $bytes = [System.IO.File]::ReadAllBytes($filePath)
                    # minimal content-type mapping
                    $ext = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
                    switch ($ext) {
                        '.html' { $ctype = 'text/html; charset=utf-8' }
                        '.htm'  { $ctype = 'text/html; charset=utf-8' }
                        '.css'  { $ctype = 'text/css' }
                        '.js'   { $ctype = 'application/javascript' }
                        '.json' { $ctype = 'application/json' }
                        '.png'  { $ctype = 'image/png' }
                        '.jpg' { $ctype = 'image/jpeg' }
                        '.jpeg' { $ctype = 'image/jpeg' }
                        '.gif'  { $ctype = 'image/gif' }
                        '.mp4'  { $ctype = 'video/mp4' }
                        '.webm' { $ctype = 'video/webm' }
                        default { $ctype = 'application/octet-stream' }
                    }
                    $response.ContentType = $ctype
                    $response.ContentLength64 = $bytes.Length
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                } else {
                    $response.StatusCode = 404
                    $msg = "404 - Not Found"
                    $buf = [System.Text.Encoding]::UTF8.GetBytes($msg)
                    $response.ContentType = 'text/plain'
                    $response.ContentLength64 = $buf.Length
                    $response.OutputStream.Write($buf, 0, $buf.Length)
                }
                $response.OutputStream.Close()
            } catch {
                # swallow per-request errors
            }
        } -ArgumentList $context, (Get-Location).Path | Out-Null
    }
} catch [System.Exception] {
    Write-Error $_.Exception.Message
} finally {
    if ($listener -and $listener.IsListening) { $listener.Stop(); $listener.Close() }
}
