<#
.SYNOPSIS
  Build and install this fork of spotatui, and make sure it's on your PATH.

.DESCRIPTION
  Installs a release build into Cargo's bin folder (%USERPROFILE%\.cargo\bin)
  with `cargo install`. Rerun it after every change to update the installed
  copy.

  Built WITHOUT the `self-update` feature on purpose: the default build checks
  the official releases on launch and installs them over itself, which would
  replace this fork with upstream spotatui.

  Features: the default set minus self-update (and minus the macOS/Linux-only
  integrations), plus cover-art, which the official Windows builds also ship.
  Pass -Sources to add Local files, Subsonic, internet radio, YouTube and Qobuz.

.EXAMPLE
  .\install-fork.ps1
  .\install-fork.ps1 -Sources
#>
param(
  [switch]$Sources
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

$features = 'telemetry,tui,streaming,audio-viz-cpal,discord-rpc,windows-media,scripting,cover-art'
if ($Sources) { $features += ',all-sources' }

Write-Host "Building and installing spotatui from $repo" -ForegroundColor Cyan
Write-Host "Features: $features"
cargo install --path $repo --locked --force --no-default-features --features $features
if ($LASTEXITCODE -ne 0) { throw "cargo install failed (exit $LASTEXITCODE)" }

# Cargo's bin folder on the user PATH (rustup normally adds it; add it if not).
$cargoBin = Join-Path $env:USERPROFILE '.cargo\bin'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$entries = @($userPath -split ';' | Where-Object { $_ })
if ($entries -notcontains $cargoBin) {
  [Environment]::SetEnvironmentVariable('Path', (($entries + $cargoBin) -join ';'), 'User')
  Write-Host "Added $cargoBin to your user PATH. Open a new terminal to pick it up." -ForegroundColor Yellow
}
if (($env:Path -split ';') -notcontains $cargoBin) { $env:Path += ";$cargoBin" }

# Another spotatui earlier on PATH (e.g. the official installer's
# %LOCALAPPDATA%\spotatui\bin) would run instead of this one.
$found = @(Get-Command spotatui -All -CommandType Application -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty Source)
$mine = Join-Path $cargoBin 'spotatui.exe'
if ($found.Count -gt 0 -and $found[0] -ne $mine) {
  Write-Host "`nHeads up: 'spotatui' currently runs $($found[0])," -ForegroundColor Yellow
  Write-Host "not this fork ($mine). Uninstall that copy or remove its folder from PATH." -ForegroundColor Yellow
} else {
  Write-Host "`nInstalled: $mine" -ForegroundColor Green
  Write-Host "Run 'spotatui' from any terminal."
}
