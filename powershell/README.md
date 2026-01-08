# PowerShell

PowerShell configuration for cross-platform shell experience.

## Installation

### Linux (Arch/Manjaro)

```bash
yay -S powershell-bin
```

### Linux (Ubuntu/Debian)

```bash
# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
# Install the GPG keys
sudo dpkg -i packages-microsoft-prod.deb
# Update package list and install
sudo apt-get update
sudo apt-get install -y powershell
```

### macOS

```bash
brew install powershell/tap/powershell
```

## Files

- `Microsoft.PowerShell_profile.ps1` - Main profile loaded on startup
- `local_profile.ps1` - Machine-specific settings (not tracked in git)

## Configuration

The profile is linked to `~/.config/powershell/` which is the default location
for PowerShell on Linux/macOS.

## Features

- **PSReadLine** - Enhanced command line editing with history search
- **Git integration** - Branch display in prompt and git aliases
- **Navigation shortcuts** - Quick directory navigation
- **Docker aliases** - Common docker commands
- **Dotnet aliases** - .NET development shortcuts
- **Custom prompt** - Shows user, host, path, and git branch

## Key Bindings

- `Up/Down Arrow` - Search history based on current input
- `Tab` - Menu completion
- `Ctrl+R` - Reverse history search (via PSReadLine)

## Aliases

### Git

- `gst` - git status
- `gco` - git checkout
- `gcm` - git commit -m
- `gpl` - git pull
- `gps` - git push
- `gd` - git diff
- `gl` - git log (last 20 commits)

### Docker

- `dps` - docker ps
- `dpsa` - docker ps -a
- `di` - docker images
- `drm` - docker rm
- `drmi` - docker rmi

### Dotnet

- `dnr` - dotnet run
- `dnb` - dotnet build
- `dnt` - dotnet test
- `dnw` - dotnet watch run

## Functions

- `mkcd <dir>` - Create directory and cd into it
- `..`, `...`, `....` - Navigate up directories
- `ff <name>` - Find files by name
- `myip` - Get public IP address

## Customization

Add machine-specific settings to `local_profile.ps1`. This file is sourced
at the end of the main profile and is ideal for:

- API keys and secrets
- Work-specific proxy settings
- Custom paths
- Machine-specific aliases

## Modules

Recommended modules to install:

```powershell
# Better tab completion for Git
Install-Module posh-git -Scope CurrentUser

# Terminal icons
Install-Module Terminal-Icons -Scope CurrentUser

# Z directory jumper
Install-Module z -Scope CurrentUser
```
