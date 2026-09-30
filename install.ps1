#Requires -Version 5.1
<#
.SYNOPSIS
    rig install.ps1 - native Windows entry point.

.DESCRIPTION
    Installs: herdr, WezTerm, gh CLI (a firstmate prerequisite), firstmate,
    and the axi CLI suite (gh-axi, chrome-devtools-axi, lavish-axi,
    quota-axi, tasks-axi, no-mistakes), then places the herdr and WezTerm
    configs from configs/.

    Safe to re-run: every step checks whether the tool is already present
    before installing it, and an existing config is never overwritten.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log  { param([string]$Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Warn { param([string]$Message) Write-Warning $Message }
function Write-Err  { param([string]$Message) Write-Host "error: $Message" -ForegroundColor Red }
function Fail       { param([string]$Message) Write-Err $Message; exit 1 }

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------------------
# package manager detection
# ---------------------------------------------------------------------------

$script:HasWinget = Test-Command 'winget'
$script:HasScoop  = Test-Command 'scoop'

if (-not $script:HasWinget -and -not $script:HasScoop) {
    Fail "Neither winget nor scoop was found. Install winget (comes with recent Windows / App Installer from the Microsoft Store) or scoop (https://scoop.sh), then re-run."
}

# ---------------------------------------------------------------------------
# tool installers
# ---------------------------------------------------------------------------

function Install-Herdr {
    if (Test-Command 'herdr') {
        Write-Log "herdr already installed; skipping."
        return
    }
    Write-Log "Installing herdr..."
    # Herdr's own installer, documented at https://herdr.dev/docs/install/
    Invoke-RestMethod https://herdr.dev/install.ps1 | Invoke-Expression
}

function Install-WezTerm {
    if (Test-Command 'wezterm') {
        Write-Log "wezterm already installed; skipping."
        return
    }
    # NOTE: the captain's brief said "wexterm" - assuming that means WezTerm,
    # the cross-platform GPU terminal emulator. See README for this assumption.
    Write-Log "Installing WezTerm..."
    if ($script:HasWinget) {
        winget install -e --id wez.wezterm --accept-source-agreements --accept-package-agreements
    }
    else {
        scoop bucket add extras
        scoop install wezterm
    }
}

function Install-GhCli {
    if (Test-Command 'gh') {
        Write-Log "gh (GitHub CLI) already installed; skipping."
        return
    }
    Write-Log "Installing GitHub CLI (gh), a firstmate prerequisite..."
    if ($script:HasWinget) {
        winget install -e --id GitHub.cli --accept-source-agreements --accept-package-agreements
    }
    else {
        scoop install gh
    }
}

function Install-Firstmate {
    if (-not (Test-Command 'git')) {
        Fail "git is required to clone firstmate but was not found."
    }

    $firstmateDir = if ($env:FIRSTMATE_DIR) { $env:FIRSTMATE_DIR } else { Join-Path $HOME 'firstmate' }

    if (Test-Path (Join-Path $firstmateDir '.git')) {
        Write-Log "firstmate already cloned at $firstmateDir; pulling latest..."
        git -C "$firstmateDir" pull --ff-only
    }
    else {
        Write-Log "Cloning firstmate into $firstmateDir..."
        git clone https://github.com/kunchenguid/firstmate "$firstmateDir"
    }

    Write-Log "firstmate cloned. Its own setup is interactive - finish it manually:"
    Write-Log "  gh auth login                        # if not already authenticated"
    Write-Log "  cd `"$firstmateDir`"; claude          # launches firstmate, which offers to install its own missing deps"
    Write-Log "Note: firstmate's default backend (tmux) is not native to Windows - running it under WSL may work better; see README."
}

function Install-NoMistakes {
    if (Test-Command 'no-mistakes') {
        Write-Log "no-mistakes already installed; skipping."
        return
    }
    Write-Log "Installing no-mistakes..."
    Invoke-RestMethod https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.ps1 | Invoke-Expression
}

$script:AxiNpmPackages = @('gh-axi', 'chrome-devtools-axi', 'lavish-axi', 'quota-axi', 'tasks-axi')

function Install-AxiSuite {
    if (-not (Test-Command 'npm')) {
        Fail "npm (Node.js) is required to install the axi CLI suite but was not found. Install Node.js (nvm-windows is recommended: https://github.com/coreybutler/nvm-windows) and re-run."
    }
    foreach ($pkg in $script:AxiNpmPackages) {
        if (Test-Command $pkg) {
            Write-Log "$pkg already installed; skipping."
        }
        else {
            Write-Log "Installing $pkg via npm..."
            npm install -g $pkg
        }
    }
}

# ---------------------------------------------------------------------------
# config placement
# ---------------------------------------------------------------------------

# Copy a repo config to its target path, unless something is already there.
# An existing, different config is left alone (never clobbered) with a warning.
function Set-Config {
    param([string]$RelPath, [string]$Dest)
    $src = Join-Path $PSScriptRoot $RelPath
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
        Fail "Config $src is missing from the repo checkout. Run install.ps1 from a full clone of rig."
    }
    if (Test-Path -LiteralPath $Dest) {
        if ((Get-FileHash -LiteralPath $src).Hash -eq (Get-FileHash -LiteralPath $Dest).Hash) {
            Write-Log "$Dest already matches rig's $RelPath; skipping."
        }
        else {
            Write-Warn "$Dest already exists and differs from rig's $RelPath; leaving it untouched."
            Write-Warn "  To adopt rig's version: Move-Item '$Dest' '$Dest.bak' and re-run install.ps1."
        }
        return
    }
    Write-Log "Placing $RelPath at $Dest..."
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Dest) | Out-Null
    Copy-Item -LiteralPath $src -Destination $Dest
}

function Install-Configs {
    # Herdr reads %APPDATA%\herdr\config.toml on Windows, unless
    # HERDR_CONFIG_PATH overrides it (https://herdr.dev/docs/configuration/).
    $herdrConfig = if ($env:HERDR_CONFIG_PATH) { $env:HERDR_CONFIG_PATH } else { Join-Path $env:APPDATA 'herdr\config.toml' }
    Set-Config 'configs\herdr\config.toml' $herdrConfig

    # WezTerm prefers wezterm\wezterm.lua under XDG_CONFIG_HOME or ~\.config
    # over ~\.wezterm.lua, so a config there would shadow ours - don't add a
    # second, ignored one.
    $shadows = @((Join-Path $HOME '.config\wezterm\wezterm.lua'))
    if ($env:XDG_CONFIG_HOME) { $shadows += (Join-Path $env:XDG_CONFIG_HOME 'wezterm\wezterm.lua') }
    foreach ($shadow in $shadows) {
        if (Test-Path -LiteralPath $shadow) {
            Write-Warn "$shadow exists and takes precedence over ~\.wezterm.lua; leaving WezTerm config untouched."
            return
        }
    }
    Set-Config 'configs\wezterm\.wezterm.lua' (Join-Path $env:USERPROFILE '.wezterm.lua')
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

function Main {
    Write-Log "Detected platform: windows"

    Install-Herdr
    Install-WezTerm
    Install-GhCli
    Install-Firstmate
    Install-NoMistakes
    Install-AxiSuite
    Install-Configs

    Write-Log "All done. See README.md for the remaining manual steps (gh auth login, launching firstmate)."
}

Main
