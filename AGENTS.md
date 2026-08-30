# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- Add durable project-specific notes here as they are discovered through real work.

## This repo

`rig` is a personal dotfiles-style setup repo: `install.sh` (macOS + WSL/Debian-Ubuntu
Linux, auto-detects which) and `install.ps1` (native Windows) each install the same
toolset end to end. Kept as two flat scripts on purpose - no shared lib/ framework;
each script is meant to be readable top to bottom. See README.md for the current
tool table and documented assumptions/manual steps.

Before adding or changing a tool's install command: verify the actual distribution
channel (official docs, `npm view <pkg>`, GitHub releases) rather than guessing from
the tool's name - this repo has already been burned once by an install brief that
assumed a tool had no public installer when it did (see git history). If a channel
can't be confirmed publicly, document it as a manual step in the README instead of
inventing a URL.

Every install step must stay idempotent (check before installing, skip with a
message if already present) and fail loudly with an actionable message on a missing
prerequisite (package manager, npm/Node, etc.) rather than half-completing silently.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
