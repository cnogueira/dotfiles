# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for Ubuntu. Everything revolves around a single bootstrap script (`install-ubuntu.sh`) that sets up a fresh machine end-to-end, plus the config files it symlinks.

## How to apply changes

There is no build or test step. Changes take effect by running (or re-running) the installer:

```bash
bash install-ubuntu.sh
```

The script is idempotent — it skips steps that are already done. To test a single section, run only the relevant commands manually rather than the whole script.

## Structure

| File/Dir | Purpose |
|---|---|
| `install-ubuntu.sh` | Main bootstrap script — the only entrypoint |
| `zshrc` | Symlinked to `~/.zshrc`; uses Oh My Zsh with theme `amuse` |
| `gitconfig` | Symlinked to `~/.gitconfig`; sets author identity and `defaultBranch = master` |
| `vscode/settings.json` | Symlinked to `~/.config/Code/User/settings.json` |
| `vscode/extensions.txt` | One extension ID per line; installed by the script via `code --install-extension` |

## What the installer sets up

1. apt packages: `zsh git curl wget ripgrep jq fzf bat ghostty`
2. GitHub CLI (`gh`) via its official apt repo
3. Fira Code font
4. Oh My Zsh + plugins: `zsh-syntax-highlighting`, `zsh-autosuggestions`
5. Symlinks for all dotfiles (zshrc, gitconfig, vscode settings, ghostty config)
6. VS Code via snap + extensions from `vscode/extensions.txt`
7. Claude Code via `curl | bash`
8. Default shell → zsh
9. SSH key (`ed25519`) if none exists
10. Node.js LTS via nvm

## Key conventions

- `batcat` is aliased to `bat` in `zshrc` (Ubuntu ships it as `batcat`).
- The ghostty config lives at `ghostty/config` (not yet committed) and is symlinked to `~/.config/ghostty/config`.
- The `.gitignore` intentionally excludes SSH keys, `.env` files, shell history, and cloud credentials — do not track those files.
- Extensions in `vscode/extensions.txt` support `#`-prefixed comment lines.
