#!/usr/bin/env bash
#
# rig install.sh - macOS and WSL/Debian/Ubuntu Linux entry point.
#
# Installs: herdr, WezTerm (macOS only - see WSL note below), firstmate,
# and the axi CLI suite (gh-axi, chrome-devtools-axi, lavish-axi, quota-axi,
# tasks-axi, no-mistakes).
#
# Safe to re-run: every step checks whether the tool is already present
# before installing it.

set -euo pipefail

# ---------------------------------------------------------------------------
# logging + small helpers
# ---------------------------------------------------------------------------

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; }
fail() { err "$*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

trap 'err "rig install.sh failed (line $LINENO). See output above for details."' ERR

# Run a command as root, using sudo if we are not already root.
as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    fail "Need root privileges to run: $* (not running as root, and sudo was not found)"
  fi
}

# ---------------------------------------------------------------------------
# platform detection
# ---------------------------------------------------------------------------

OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="macos" ;;
  Linux)  PLATFORM="linux" ;;
  *) fail "Unsupported OS '$OS'. This script supports macOS and Debian/Ubuntu-based Linux (including WSL)." ;;
esac

IS_WSL=false
if [[ "$PLATFORM" == "linux" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
fi

if [[ "$PLATFORM" == "macos" ]]; then
  have brew || fail "Homebrew is required on macOS but was not found. Install it from https://brew.sh and re-run."
elif [[ "$PLATFORM" == "linux" ]]; then
  have apt-get || fail "This script's Linux path supports Debian/Ubuntu (apt-get). apt-get was not found on this system."
fi

# ---------------------------------------------------------------------------
# tool installers
# ---------------------------------------------------------------------------

install_herdr() {
  if have herdr; then
    log "herdr already installed; skipping."
    return
  fi
  log "Installing herdr..."
  if [[ "$PLATFORM" == "macos" ]]; then
    brew install herdr
  else
    curl -fsSL https://herdr.dev/install.sh | sh
  fi
}

install_wezterm() {
  # WezTerm is a GUI app. Under WSL it must be installed on the Windows
  # host, not inside the Linux filesystem - point at install.ps1 instead.
  if [[ "$PLATFORM" == "linux" ]]; then
    log "Skipping WezTerm here: it's a GUI terminal that has to run on the Windows host, not inside WSL."
    log "On the Windows side: run install.ps1 from this repo, or 'winget install -e --id wez.wezterm'."
    return
  fi
  if have wezterm; then
    log "wezterm already installed; skipping."
    return
  fi
  # NOTE: the captain's brief said "wexterm" - assuming that means WezTerm,
  # the cross-platform GPU terminal emulator. See README for this assumption.
  log "Installing WezTerm..."
  brew install --cask wezterm
}

install_gh_cli() {
  if have gh; then
    log "gh (GitHub CLI) already installed; skipping."
    return
  fi
  log "Installing GitHub CLI (gh), a firstmate prerequisite..."
  if [[ "$PLATFORM" == "macos" ]]; then
    brew install gh
  else
    local keyring=/etc/apt/keyrings/githubcli-archive-keyring.gpg
    as_root mkdir -p -m 755 /etc/apt/keyrings
    local tmp
    tmp="$(mktemp)"
    wget -nv -O "$tmp" https://cli.github.com/packages/githubcli-archive-keyring.gpg
    as_root cp "$tmp" "$keyring"
    as_root chmod go+r "$keyring"
    as_root mkdir -p -m 755 /etc/apt/sources.list.d
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring] https://cli.github.com/packages stable main" \
      | as_root tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    as_root apt-get update
    as_root apt-get install -y gh
  fi
}

FIRSTMATE_DIR="${FIRSTMATE_DIR:-$HOME/firstmate}"

install_firstmate() {
  have git || fail "git is required to clone firstmate but was not found."
  if [[ -d "$FIRSTMATE_DIR/.git" ]]; then
    log "firstmate already cloned at $FIRSTMATE_DIR; pulling latest..."
    git -C "$FIRSTMATE_DIR" pull --ff-only
  else
    log "Cloning firstmate into $FIRSTMATE_DIR..."
    git clone https://github.com/kunchenguid/firstmate "$FIRSTMATE_DIR"
  fi
  log "firstmate cloned. Its own setup is interactive - finish it manually:"
  log "  gh auth login                 # if not already authenticated"
  log "  cd $FIRSTMATE_DIR && claude   # launches firstmate, which offers to install its own missing deps"
}

install_no_mistakes() {
  if have no-mistakes; then
    log "no-mistakes already installed; skipping."
    return
  fi
  log "Installing no-mistakes..."
  curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh
}

AXI_NPM_PACKAGES=(gh-axi chrome-devtools-axi lavish-axi quota-axi tasks-axi)

install_axi_suite() {
  have npm || fail "npm (Node.js) is required to install the axi CLI suite but was not found. Install Node.js (nvm is recommended: https://github.com/nvm-sh/nvm) and re-run."
  local pkg
  for pkg in "${AXI_NPM_PACKAGES[@]}"; do
    if have "$pkg"; then
      log "$pkg already installed; skipping."
    else
      log "Installing $pkg via npm..."
      npm install -g "$pkg"
    fi
  done
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

main() {
  local platform_desc="$PLATFORM"
  [[ "$IS_WSL" == true ]] && platform_desc="$platform_desc (WSL)"
  log "Detected platform: $platform_desc"

  install_herdr
  install_wezterm
  install_gh_cli
  install_firstmate
  install_no_mistakes
  install_axi_suite

  log "All done. See README.md for the remaining manual steps (gh auth login, launching firstmate, and WezTerm on the Windows host if you're under WSL)."
}

main "$@"
