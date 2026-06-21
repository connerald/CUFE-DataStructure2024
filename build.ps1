param(
    [string]$OutputDir = "build"
)

$ErrorActionPreference = "Stop"

$gcc = Get-Command gcc -ErrorAction SilentlyContinue
if (-not $gcc) {
    Write-Error "gcc was not found. Please install GCC and make sure it is available in PATH."
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$root = (Get-Location).Path
$outputFullPath = (Resolve-Path $OutputDir).Path
$files = Get-ChildItem -Recurse -File -Filter "*.c" |
    Where-Object { -not $_.FullName.StartsWith($outputFullPath, [StringComparison]::OrdinalIgnoreCase) }

if (-not $files) {
    Write-Host "No C source files found."
    exit 0
}

$failed = @()

foreach ($file in $files) {
    $relative = $file.FullName.Substring($root.Length + 1)
    $safeName = $relative -replace "[\\/]", "__"
    $output = Join-Path $OutputDir ([IO.Path]::ChangeExtension($safeName, ".exe"))

    Write-Host "Compiling $relative"
    & gcc -std=c17 -Wall -Wextra -pedantic $file.FullName -o $output

    if ($LASTEXITCODE -ne 0) {
        $failed += $relative
    }
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "Build failed:"
    $failed | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host ""
Write-Host "Build succeeded. Output directory: $OutputDir"
