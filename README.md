# rig

Cross-platform setup for the captain's standard toolset: one script installs
everything and places its configs, on macOS, WSL, or native Windows.

## What gets installed

| Tool | What it is | macOS | WSL / Linux | Native Windows |
|---|---|---|---|---|
| [herdr](https://herdr.dev) | Terminal/agent runtime multiplexer | `brew install herdr` | `herdr.dev` install script | `herdr.dev` install script |
| [WezTerm](https://wezterm.org) | GPU-accelerated terminal emulator | `brew install --cask wezterm` | skipped (GUI app - see below) | `winget`/`scoop` |
| [gh CLI](https://cli.github.com) | GitHub CLI (firstmate dependency) | `brew install gh` | apt (official GitHub apt repo) | `winget`/`scoop` |
| [firstmate](https://github.com/kunchenguid/firstmate) | Autonomous agent orchestrator | `git clone`, then manual `claude` launch | same | same |
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | Pre-push code review/CI gate | official curl installer | official curl installer | official PowerShell installer |
| gh-axi, chrome-devtools-axi, lavish-axi, quota-axi, tasks-axi | AXI-ergonomic CLI suite | `npm install -g` | `npm install -g` | `npm install -g` |

Every step is idempotent - re-running the installer skips anything already present
and says so, rather than reinstalling or erroring.

## Configs

After installing the tools, both scripts place the captain's configs from
`configs/`:

| Config | Repo file | macOS | WSL / Linux | Native Windows |
|---|---|---|---|---|
| herdr | `configs/herdr/config.toml` | `~/.config/herdr/config.toml` | `~/.config/herdr/config.toml` | `%APPDATA%\herdr\config.toml` |
| WezTerm | `configs/wezterm/.wezterm.lua` | `~/.wezterm.lua` | skipped (placed on the Windows host by `install.ps1`) | `%USERPROFILE%\.wezterm.lua` |

Target paths follow each tool's docs: herdr's
[configuration page](https://herdr.dev/docs/configuration/) (a set
`HERDR_CONFIG_PATH` is honored as the herdr target instead) and WezTerm's
[config file lookup](https://wezterm.org/config/files.html).

An existing config is never overwritten. If the target already matches rig's
copy the step is skipped; if it differs, the installer leaves it alone and
prints a warning with the command to move it aside (to `*.bak`) and re-run.
The WezTerm step is also skipped if a `wezterm/wezterm.lua` exists under
`$XDG_CONFIG_HOME` or `~/.config`, since WezTerm would load that one instead of
`~/.wezterm.lua`.

To update the repo copies after changing a config locally, copy the live file
back over the one in `configs/` and commit it. This repo is public, so check
the diff for secrets or machine-specific paths first.

## Running it

**macOS or WSL / Debian-Ubuntu Linux:**

```bash
./install.sh
```

**Native Windows (PowerShell):**

```powershell
.\install.ps1
```

Both scripts auto-detect the platform they're running on and fail loudly with an
actionable message if a required package manager is missing (Homebrew on macOS,
`apt-get` on Linux, winget/scoop on Windows) rather than half-completing silently.

## Assumptions and manual steps

- **"wexterm" is read as WezTerm.** The captain's brief referred to "wexterm";
  this repo assumes that means [WezTerm](https://wezterm.org), the cross-platform
  GPU-accelerated terminal emulator, since no tool literally named "wexterm"
  exists. If that's wrong, say so and this gets fixed.
- **WezTerm under WSL runs on the Windows host, not inside WSL.** WezTerm is a
  GUI application; it can't run inside the WSL filesystem. `install.sh`'s Linux
  path detects this and skips the WezTerm step with a pointer back to
  `install.ps1` (or a plain `winget install -e --id wez.wezterm`) to run on the
  Windows side.
- **Herdr does have a public install channel.** herdr.dev publishes install
  scripts for macOS/Linux (`curl -fsSL https://herdr.dev/install.sh | sh`) and
  Windows (PowerShell), plus a Homebrew formula (`brew install herdr`) and
  GitHub releases at [herdrdev/herdr](https://github.com/herdrdev/herdr). This
  repo uses those documented channels rather than a bundled binary.
- **firstmate's setup is interactive by design.** Its own README documents
  `git clone https://github.com/kunchenguid/firstmate`, then launching an agent
  harness (`claude` in this repo's case) inside the clone, at which point
  firstmate self-detects and offers to install its own missing dependencies.
  Both `install.sh` and `install.ps1` clone the repo and print the exact
  follow-up commands (`gh auth login`, then `claude` from inside the clone) -
  they don't attempt to drive that interactive flow themselves.
- **`gh` (GitHub CLI) is installed as a firstmate prerequisite** but
  `gh auth login` is left as a manual step, since it's an interactive OAuth
  flow the script shouldn't launch unprompted.
- **On native Windows, firstmate's default backend is tmux**, which isn't
  native to Windows. If firstmate's own setup can't find a working backend,
  running it from WSL instead (via `install.sh`) is likely the smoother path.
- **The axi CLI suite packages were confirmed on the public npm registry**
  (`npm view <pkg>`) before writing their install commands: `gh-axi`,
  `chrome-devtools-axi`, `lavish-axi`, `quota-axi`, and `tasks-axi` all resolve
  publicly, so all five install via `npm install -g <pkg>`. `no-mistakes` ships
  its own installer instead (see table above).

## Repo layout

- `install.sh` - single entry point for macOS and WSL/Debian/Ubuntu Linux,
  auto-detecting which one it's running on.
- `install.ps1` - single entry point for native Windows.
- `configs/` - the herdr and WezTerm configs the installers place (see
  [Configs](#configs)).

Kept deliberately as two flat, readable scripts rather than a shared-library
framework - each is small enough to read top to bottom.
