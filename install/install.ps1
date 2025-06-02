# PowerShell install script for Oh My Posh (Chuya)
# Usage: Invoke-WebRequest -Uri "https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/install/install.ps1" -OutFile install.ps1; .\install.ps1

$ErrorActionPreference = 'Stop'

# Configuration
$themeUrl = "https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/oh-my-posh/chuya.omp.json"
$themeDir = "$HOME/.chuya/oh-my-posh" -replace '/', '\'
$themePath = Join-Path $themeDir 'chuya.omp.json'
$profilePath = $PROFILE

Write-Host "🔧 Installing Oh My Posh via the official script..."
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))

Write-Host "📁 Creating personal theme folder..."
if (-not (Test-Path $themeDir)) {
    New-Item -ItemType Directory -Path $themeDir | Out-Null
}

Write-Host "🌐 Downloading custom theme..."
try {
    Invoke-WebRequest -Uri $themeUrl -OutFile $themePath -UseBasicParsing
} catch {
    Write-Warning "⚠️ Failed to download custom theme, using default theme."
    $defaultTheme = oh-my-posh get shell pwsh | ConvertFrom-Json | Select-Object -ExpandProperty config
    Copy-Item $defaultTheme $themePath
}

Write-Host "⚙️ Configuring PowerShell profile..."
$initLine = "oh-my-posh init pwsh --config '$themePath' | Invoke-Expression"
$aliasLine = "Import-Module PSReadLine"

if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath | Out-Null
}

$profileContent = Get-Content $profilePath -Raw
if ($profileContent -notmatch 'oh-my-posh') {
    Add-Content $profilePath "`n# Oh My Posh configuration by Chuya`n$initLine`n$aliasLine`n"
    Write-Host "✅ Configuration added to $profilePath"
} else {
    Write-Host "ℹ️ Oh My Posh configuration already present in $profilePath"
}

Write-Host "🎉 Installation complete!" 