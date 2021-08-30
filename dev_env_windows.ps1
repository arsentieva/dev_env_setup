#-------------------------------------------------------------------------------#
#                                                                               #
# This script installs all the stuff I need to develop the things I develop.    #
# Run PowerShell with admin priveleges, type `env-windows`,                     #
# and go make a cup of macha.                                                   #
#                                                                               #
#                                                                         -Anna #
#                                                                               #
#-------------------------------------------------------------------------------#

#
# Functions
#

function Update-Environment-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") `
        + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Push-User-Path($userPath) {
    $path = [Environment]::GetEnvironmentVariable('Path', 'User')
    $newpath = "$userPath;$path"
    [Environment]::SetEnvironmentVariable("Path", $newpath, 'User')
    Update-Environment-Path
}

function Check-Command($name) {
    return [bool](Get-Command -Name $name -ErrorAction SilentlyContinue)
}

# -----------------------------------------------------------------------------
$computerName = Read-Host 'Enter New Computer Name'
Write-Host "Renaming this computer to: " $computerName  -ForegroundColor Magenta
Rename-Computer -NewName $computerName
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Disable Sleep on AC Power..." -ForegroundColor Green
Write-Host "------------------------------------" -ForegroundColor Cyan
Powercfg /Change monitor-timeout-ac 20
Powercfg /Change standby-timeout-ac 0
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Add 'This PC' Desktop Icon..." -ForegroundColor Green
Write-Host "------------------------------------" -ForegroundColor Green
$thisPCIconRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
$thisPCRegValname = "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" 
$item = Get-ItemProperty -Path $thisPCIconRegPath -Name $thisPCRegValname -ErrorAction SilentlyContinue 
if ($item) { 
    Set-ItemProperty  -Path $thisPCIconRegPath -name $thisPCRegValname -Value 0  
} 
else { 
    New-ItemProperty -Path $thisPCIconRegPath -Name $thisPCRegValname -Value 0 -PropertyType DWORD | Out-Null  
} 

# To list all appx packages:
# Get-AppxPackage | Format-Table -Property Name,Version,PackageFullName
Write-Host "Removing UWP Rubbish..." -ForegroundColor Green
Write-Host "------------------------------------" -ForegroundColor Orange
$uwpRubbishApps = @(
    "Microsoft.Messaging",
    "king.com.CandyCrushSaga",
    "king.com.FarmHeroesSaga",
    "Microsoft.BingNews",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.People",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.YourPhone",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.SkypeApp",
    "Microsoft.ZuneMusic",
    "Microsoft.GetHelp",
foreach ($uwp in $uwpRubbishApps) {
    Get-AppxPackage -Name $uwp | Remove-AppxPackage
}

# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Starting UWP apps to upgrade..." -ForegroundColor Green
Write-Host "------------------------------------" -ForegroundColor Green
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()


# Choco
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
#Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
if (Check-Command -cmdname 'choco') {
    Write-Host "Choco is already installed, skip installation." -ForegroundColor yellow
}
else {
    Write-Host ""
    Write-Host "Installing Chocolate for Windows..." -ForegroundColor Green
    Write-Host "------------------------------------" -ForegroundColor Green
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
Update-Environment-Path

Write-Host ""
Write-Host "Installing Applications..." -ForegroundColor Green
Write-Host "------------------------------------" -ForegroundColor Green
Write-Host "Some software like Google Chrome require the true Internet first" -ForegroundColor Yellow

$Apps = @(
    #BROWSERS
    "googlechrome",
    "firefox",
    "vlc",
    "dotnetcore-sdk",
    # "openssl.light",
    "sysinternals",   
    "nuget.commandline",
    "beyondcompare",
    "inkscape",
    "irfanview",
    "chocolateygui",
    "obs-studio",
    "everything",

    # Font to support PowerShell Tooling:
    #'Be sure to configure Windows Terminal fonts! Suggest using "fontFace": "Cascadia Code PL"'
    "cascadiacode",
    "cascadiamono",
    "cascadiacodepl",
    "cascadiamonopl",

    #coding
    "awscli",
    "postman",

    # languages
    "jdk8",
    "nodejs.install",
    # "php",
    # "ruby",
    # "ruby2.devkit",
    
    # "docker",
    # "docker-machine",
    # "docker-compose",
    # "docker-for-windows",
  
    # IDE & TOOL
    "visualstudiocode", # includes dotnet
    "github-desktop",
    "powershell-core",
    "gitkraken",
    "diffmerge",
    "microsoft-windows-terminal",
    # "tortoisegit",

    # Database
    # "mysql",
    # "mysql.workbench",
    "postgresql",

    #PRODUCTIVITY TOOLS 
    "slack",
    "greenshot",
    "notepadplusplus.install",
    "notion",
    "zoom"
    )


foreach ($app in $Apps) {
    choco install $app -y
    Update-Environment-Path
}

# Utils
Get-Command -Module Microsoft.PowerShell.Archive

#
# Git
# Puts gitinstall\bin on path. This setting will override /GitOnlyOnPath
choco install git --yes --params '/GitAndUnixToolsOnPath'
#choco install tortoisegit --yes
Update-Environment-Path

git config --global core.editor "code --wait"

# Aliases
git config --global alias.pom 'pull origin main'
git config --global alias.last 'log -1 HEAD'
git config --global alias.ls "log --pretty=format:'%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]' --decorate --date=short --graph"
git config --global alias.standup "log --since yesterday --author $(git config user.email) --pretty=short"
git config --global alias.ammend "commit -a --amend"
git config --global alias.everything "! git pull && git submodule update --init --recursive"
git config --global alias.aliases "config --get-regexp alias"


# PowerShell Tooling for Git
Install-Module posh-git -Force -Scope CurrentUser
Install-Module oh-my-posh -Force -Scope CurrentUser
Set-Prompt
Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
Add-Content $PROFILE "`nImport-Module posh-git`nImport-Module oh-my-posh`nSet-Theme Paradox"



# Python
git clone https://github.com/pyenv-win/pyenv-win.git $env:USERPROFILE\.pyenv
[Environment]::SetEnvironmentVariable("PYENV", "$env:USERPROFILE\.pyenv\pyenv-win", 'User')
Push-User-Path "%PYENV%\bin"
Push-User-Path "%PYENV%\shims"
pyenv rehash
pyenv install 2.7.9
pyenv install 3.9.0
pyenv global 3.9.0 # default to latest
pyenv rehash
python -m pip install -U pip
pip install virtualenv
Update-Environment-Path
Write-Output "Python, Pyenv, and virtualenv installed! Use 'python3 -m venv <dir>' to create an environment"

# Node
npm install --global --production npm-windows-upgrade
npm-windows-upgrade --npm-version latest
npm install -g gulp-cli 
npm install -g yo
npm install -g mocha
npm install -g install-peerdeps
npm install -g typescript
# Bower
npm install -g bower
# Grunt
npm install -g grunt-cli

#
# Docker
# 
# Hyper-V required for docker and other things // this does not work on Windows 10 Home
Enable-WindowsOptionalFeature -Online -FeatureName:Microsoft-Hyper-V -All -NoRestart


# Note: VirtualBox sucks, see instructions here to run minikube: https://medium.com/@JockDaRock/minikube-on-windows-10-with-hyper-v-6ef0f4dc158c
# TLDR: run with `minikube start --vm-driver hyperv --hyperv-virtual-switch "Primary Virtual Switch"`


# Yarn
# ?? choco install yarn --yes



#
# VS Code
#

# choco install visualstudiocode --yes 
# Update-Environment-Path

# Install VSCode Extensions
code --install-extension robertohuertasm.vscode-icons
code --install-extension CoenraadS.bracket-pair-colorizer
code --install-extension eamodio.gitlens
code --install-extension oderwat.indent-rainbow
code --install-extension sdras.night-owl
Start-Process https://github.com/sdras/night-owl-vscode-theme

# PowerShell support
code --install-extension ms-vscode.PowerShell

# CSharp support
code --install-extension ms-vscode.csharp

# PHP support
#code --install-extension HvyIndustries.crane

# Ruby support
#code --install-extension rebornix.Ruby

# C++ support
#code --install-extension ms-vscode.cpptools

# HTML, CSS, JavaScript support
code --install-extension Zignd.html-css-class-completion
code --install-extension robinbentley.sass-indented
code --install-extension dbaeumer.vscode-eslint
code --install-extension dzannotti.vscode-babel-coloring
code --install-extension esbenp.prettier-vscode
code --install-extension formulahendry.auto-rename-tag

# NPM support
code --install-extension eg2.vscode-npm-script
code --install-extension christian-kohler.npm-intellisense

# Jasmin Support
#code --install-extension hbenl.vscode-jasmine-test-adapter

# Jest support
#code --install-extension Orta.vscode-jest

# React Native support
code --install-extension vsmobile.vscode-react-native
npm install -g create-react-native-app
npm install -g react-native-cli

# Docker support
code --install-extension PeterJausovec.vscode-docker
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

# PlantUML support
code --install-extension jebbs.plantuml

# Markdown Support 
code --install-extension yzhang.markdown-all-in-one
code --install-extension mdickin.markdown-shortcuts

# WSL Support
code --install-extension ms-vscode-remote.remote-wsl


# Windows Subsystem for Linux
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
Enable-WindowsOptionalFeature -Online -FeatureName $("VirtualMachinePlatform", "Microsoft-Windows-Subsystem-Linux")
Update-Environment-Path
wsl --set-default-version 2
Start-Process https://aka.ms/wslstore

