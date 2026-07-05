#!/usr/bin/env pwsh
# Optional full-browser setup for stronger JS/WAF fallbacks.
# Windows-native companion to setup/browser.sh.
[CmdletBinding()]
param(
  # Install Node.js LTS via winget when missing. Requires explicit user consent:
  # agents must ask before passing this flag.
  [switch] $InstallNode
)

# "Continue", not "Stop": Windows PowerShell 5.1 promotes native stderr output
# to terminating errors under "Stop". Native calls below check $LASTEXITCODE.
$ErrorActionPreference = "Continue"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Templates = Join-Path $Root "skills/aioffice-searchpro/engine/templates"

function Ok($Message) { Write-Host "ok  $Message" }
function Warn($Message) { Write-Host "warn $Message" }
function Bad($Message) { Write-Host "bad $Message"; exit 1 }

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  if (-not $InstallNode) {
    Bad "Node.js is required. Install Node 18+ first, or re-run with -InstallNode to install it via winget (ask the user first)."
  }
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Bad "winget is not available. Install Node 18+ manually from https://nodejs.org/ and re-run."
  }
  Ok "Installing Node.js LTS via winget..."
  & winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -ne 0) {
    Bad "winget install failed. Install Node 18+ manually from https://nodejs.org/ and re-run."
  }
  # winget only updates PATH for new shells; pick the change up in this session.
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Bad "Node.js was installed but is not visible in this session. Open a new terminal and re-run setup/browser.ps1."
  }
}
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  Bad "npm is required. Install Node/npm first."
}

Ok "Node.js found: $(& node --version)"
Ok "npm found: $(& npm --version)"

Push-Location $Templates
try {
  & npm install
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  & npx patchright install chrome
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
  Pop-Location
}
Ok "local real-Chrome Playwright dependencies installed"

if (Get-Command claude -ErrorAction SilentlyContinue) {
  $mcpList = ""
  try { $mcpList = & claude mcp list 2>$null | Out-String } catch { $mcpList = "" }
  if ($mcpList -match "(?im)^playwright\b") {
    Ok "Playwright MCP is already configured"
  } else {
    & claude mcp add playwright -s user -- npx -y "@playwright/mcp@latest"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Ok "Playwright MCP added at user scope"
  }
} else {
  Warn "Claude Code CLI not found; skipped Playwright MCP registration"
}

Write-Host ""
Write-Host "Browser setup complete."
Write-Host "Restart Claude Code or run /reload-plugins so newly installed MCP/tools are visible."
