#
# dotphiles : https://github.com/dotphiles/dotphiles
#
# PowerShell profile configuration
#
# Authors:
#   Chris <your-email@example.com>
#

# =============================================================================
# Environment Variables
# =============================================================================

$env:EDITOR = "vim"
$env:VISUAL = "vim"

# =============================================================================
# Module Imports
# =============================================================================

# Import PSReadLine for better command line editing
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    
    # Set vi mode (comment out for default emacs mode)
    # Set-PSReadLineOption -EditMode Vi
    
    # Enable predictive IntelliSense
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    
    # History settings
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    
    # Colors for syntax highlighting
    Set-PSReadLineOption -Colors @{
        Command            = 'Yellow'
        Parameter          = 'Green'
        String             = 'Cyan'
        Operator           = 'Magenta'
        Variable           = 'Green'
        Number             = 'White'
        Type               = 'Gray'
        Comment            = 'DarkGreen'
        Keyword            = 'Green'
        Error              = 'Red'
        Selection          = "$([char]0x1b)[7m"
        InlinePrediction   = 'DarkGray'
    }
}

# =============================================================================
# Aliases
# =============================================================================

# Navigation
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name la -Value Get-ChildItem
Set-Alias -Name which -Value Get-Command

# Git aliases
function gst { git status }
function gco { git checkout $args }
function gcm { git commit -m $args }
function gpl { git pull }
function gps { git push }
function gd { git diff $args }
function gl { git log --oneline -n 20 }

# =============================================================================
# Functions
# =============================================================================

# Create and enter directory
function mkcd {
    param([string]$path)
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Set-Location -Path $path
}

# Quick directory navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

# Find files by name
function ff {
    param([string]$name)
    Get-ChildItem -Recurse -Filter "*$name*" -ErrorAction SilentlyContinue
}

# Get public IP
function myip {
    (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
}

# Docker shortcuts
function dps { docker ps $args }
function dpsa { docker ps -a $args }
function di { docker images $args }
function drm { docker rm $args }
function drmi { docker rmi $args }

# Dotnet shortcuts
function dnr { dotnet run $args }
function dnb { dotnet build $args }
function dnt { dotnet test $args }
function dnw { dotnet watch run $args }

# =============================================================================
# Prompt Configuration
# =============================================================================

function prompt {
    $location = Get-Location
    $user = $env:USER ?? $env:USERNAME
    $host_name = [System.Net.Dns]::GetHostName()
    
    # Git branch info
    $gitBranch = ""
    if (Test-Path .git) {
        $branch = git branch --show-current 2>$null
        if ($branch) {
            $gitBranch = " ($branch)"
        }
    }
    
    # Build prompt
    Write-Host "$user@$host_name" -ForegroundColor Green -NoNewline
    Write-Host ":" -NoNewline
    Write-Host "$location" -ForegroundColor Blue -NoNewline
    Write-Host "$gitBranch" -ForegroundColor Yellow -NoNewline
    Write-Host ""
    return "$ "
}

# =============================================================================
# Local Configuration
# =============================================================================

# Source local profile if it exists
$localProfile = Join-Path (Split-Path $PROFILE) "local_profile.ps1"
if (Test-Path $localProfile) {
    . $localProfile
}

# =============================================================================
# Startup
# =============================================================================

# Display welcome message
Write-Host "PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host "Type 'Get-Help' for help" -ForegroundColor DarkGray
