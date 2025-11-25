# PowerShell install script for Chuya
# Usage: Invoke-WebRequest -Uri "https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/install/install.ps1" -OutFile install.ps1; .\install.ps1

$ErrorActionPreference = 'Stop'

# Ask user for installation method
Write-Host "🎯 Chuya Setup" -ForegroundColor Cyan
Write-Host "Choose your installation method:" -ForegroundColor Yellow
Write-Host "1. Git Clone (Recommended - keeps configuration up to date)" -ForegroundColor Green
Write-Host "2. Manual Download (Standalone installation)" -ForegroundColor White
Write-Host ""

do {
    $choice = Read-Host "Enter your choice (1 or 2)"
} while ($choice -notin @("1", "2"))

$useGit = $choice -eq "1"

# Configuration
$chuya_dir = "$HOME\.chuya"
$profileDir = "$chuya_dir\powershell"
$profileSourcePath = "$profileDir\profile.ps1"
$userProfilePath = $PROFILE


if ($useGit) {
    Write-Host "📦 Using Git installation method..." -ForegroundColor Green
    
    # Check if git is available
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "❌ Git is not installed or not in PATH. Please install Git first or choose manual installation."
        exit 1
    }
    
    # Clone the repository
    Write-Host "📥 Cloning .chuya repository..."
    if (Test-Path $chuya_dir) {
        Write-Host "📁 Directory $chuya_dir already exists, updating..."
        Set-Location $chuya_dir
        git pull origin main
    } else {
        git clone https://github.com/AT-Lorlando/.chuya.git $chuya_dir
    }
    
    # Add source line to user profile
    Write-Host "⚙️ Configuring PowerShell profile..."
    $sourceLine = ". `"$profileSourcePath`""
    
    if (-not (Test-Path $userProfilePath)) {
        New-Item -ItemType File -Path $userProfilePath -Force | Out-Null
    }
    
    $profileContent = Get-Content $userProfilePath -Raw -ErrorAction SilentlyContinue
    if (-not $profileContent -or $profileContent -notmatch [regex]::Escape($sourceLine)) {
        Add-Content $userProfilePath "`n# Chuya configuration`n$sourceLine`n"
        Write-Host "✅ Source line added to $userProfilePath" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ Source line already present in $userProfilePath" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "📥 Using manual download method..." -ForegroundColor White
    
    # Create directories
    Write-Host "📁 Creating directories..."
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    # Download and create the profile.ps1 file
    Write-Host "📄 Downloading profile.ps1..."
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/AT-Lorlando/.chuya/main/powershell/profile.ps1" -OutFile $profileSourcePath -UseBasicParsing
        Write-Host "✅ Profile downloaded successfully" -ForegroundColor Green
    } catch {
        Write-Warning "⚠️ Failed to download profile.ps1: $($_.Exception.Message)"
    }
    
    # Add source line to user profile
    Write-Host "⚙️ Configuring PowerShell profile..."
    $sourceLine = ". `"$profileSourcePath`""
    
    if (-not (Test-Path $userProfilePath)) {
        New-Item -ItemType File -Path $userProfilePath -Force | Out-Null
    }
    
    $profileContent = Get-Content $userProfilePath -Raw -ErrorAction SilentlyContinue
    if (-not $profileContent -or $profileContent -notmatch [regex]::Escape($sourceLine)) {
        Add-Content $userProfilePath "`n# Chuya configuration`n$sourceLine`n"
        Write-Host "✅ Source line added to $userProfilePath" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ Source line already present in $userProfilePath" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎉 Installation complete!" -ForegroundColor Green
Write-Host "🔄 Please restart PowerShell or run '. `$PROFILE' to apply changes." -ForegroundColor Cyan

if ($useGit) {
    Write-Host "📝 Git method: Your configuration will stay updated with the repository." -ForegroundColor Green
} else {
    Write-Host "📝 Manual method: To update configuration, re-run this script." -ForegroundColor White
}