#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

step()  { echo -e "\n${GREEN}→${RESET} $1"; }
info()  { echo -e "  ${CYAN}$1${RESET}"; }
warn()  { echo -e "  ${YELLOW}⚠ $1${RESET}"; }
title() { echo -e "\n${BOLD}$1${RESET}"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_EMAIL="cristofor.nogueira@gmail.com"

# ─────────────────────────────────────────────
title "=== System packages ==="
# ─────────────────────────────────────────────

step "Updating apt..."
sudo apt update -q

step "Installing core CLI tools..."
sudo apt install -y \
  zsh \
  git \
  curl \
  wget \
  ripgrep \
  jq \
  fzf \
  bat \
  ghostty \
  flameshot
info "Installed: zsh, git, curl, wget, ripgrep, jq, fzf, bat, ghostty, flameshot"

# Ubuntu ships bat as 'batcat' — alias it
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  step "Aliasing batcat → bat..."
  mkdir -p ~/.local/bin
  ln -sf "$(which batcat)" ~/.local/bin/bat
fi

# Install gh (GitHub CLI) via official repo for up-to-date versions
step "Installing GitHub CLI (gh)..."
if ! command -v gh &>/dev/null; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update -q && sudo apt install -y gh
  info "gh installed"
else
  info "gh already installed, skipping"
fi

# ─────────────────────────────────────────────
title "=== Fonts ==="
# ─────────────────────────────────────────────

step "Installing Fira Code (ligatures for VS Code)..."
sudo apt install -y fonts-firacode
info "Fira Code installed"

# ─────────────────────────────────────────────
title "=== Oh My Zsh ==="
# ─────────────────────────────────────────────

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  step "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  info "Oh My Zsh already installed, skipping"
fi

step "Installing zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  info "zsh-syntax-highlighting installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  info "zsh-autosuggestions installed"
fi

# ─────────────────────────────────────────────
title "=== Dotfiles ==="
# ─────────────────────────────────────────────

step "Symlinking dotfiles..."
ln -sf "$DOTFILES_DIR/zshrc"       "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/gitconfig"   "$HOME/.gitconfig"

mkdir -p "$HOME/.config/ghostty"
ln -sf "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

# ─────────────────────────────────────────────
title "=== VS Code ==="
# ─────────────────────────────────────────────

if ! command -v code &>/dev/null; then
  step "Installing VS Code..."
  sudo snap install code --classic
  info "VS Code installed via snap"
else
  info "VS Code already installed, skipping"
fi

step "Symlinking VS Code settings..."
mkdir -p "$HOME/.config/Code/User"
ln -sf "$DOTFILES_DIR/vscode/settings.json" "$HOME/.config/Code/User/settings.json"

step "Installing VS Code extensions..."
if [ -f "$DOTFILES_DIR/vscode/extensions.txt" ]; then
  while IFS= read -r ext; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue
    code --install-extension "$ext" --force
  done < "$DOTFILES_DIR/vscode/extensions.txt"
  info "Extensions installed"
else
  warn "vscode/extensions.txt not found, skipping"
fi

# ─────────────────────────────────────────────
title "=== Claude Code ==="
# ─────────────────────────────────────────────

if ! command -v claude &>/dev/null; then
  step "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
  info "Claude Code installed"
else
  info "Claude Code already installed, skipping"
fi

# ─────────────────────────────────────────────
title "=== Default shell ==="
# ─────────────────────────────────────────────

if [ "$SHELL" != "$(which zsh)" ]; then
  step "Setting zsh as default shell..."
  chsh -s "$(which zsh)"
  info "Default shell changed to zsh (takes effect on next login)"
else
  info "zsh is already the default shell"
fi

# ─────────────────────────────────────────────
title "=== SSH key ==="
# ─────────────────────────────────────────────

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  step "No SSH key found — generating one..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  info "Using email: $GIT_EMAIL"
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
  eval "$(ssh-agent -s)" > /dev/null
  ssh-add "$HOME/.ssh/id_ed25519"
  info "SSH key generated: ~/.ssh/id_ed25519"
  echo ""
  echo -e "  ${YELLOW}Your public key (copy this to GitHub → Settings → SSH keys):${RESET}"
  echo ""
  cat "$HOME/.ssh/id_ed25519.pub"
  echo ""
else
  info "SSH key already exists at ~/.ssh/id_ed25519, skipping"
fi

# ─────────────────────────────────────────────
title "=== Node.js (via nvm) ==="
# ─────────────────────────────────────────────

export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
  step "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default lts/*
  info "Node $(node --version) installed"
else
  info "nvm already installed, skipping"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# ─────────────────────────────────────────────
title "=== ESLint ==="
# ─────────────────────────────────────────────

step "Installing ESLint (global)..."
if ! command -v eslint &>/dev/null; then
  npm install -g eslint
  info "ESLint $(eslint --version) installed"
else
  info "ESLint already installed, skipping"
fi

# ─────────────────────────────────────────────
title "=== Done! ==="
# ─────────────────────────────────────────────

echo ""
echo -e "${GREEN}✓ Automated setup complete.${RESET}"
echo ""
echo -e "${BOLD}Next steps (manual — require authentication):${RESET}"
echo ""
echo -e "  ${CYAN}1. Authenticate GitHub CLI${RESET}"
echo "     Run: gh auth login"
echo "     → Choose: GitHub.com → HTTPS → Login with a web browser"
echo ""
echo -e "  ${CYAN}2. Authenticate Claude Code${RESET}"
echo "     Run: claude"
echo "     → It will open a browser window on first launch."
echo "     → Requires a Claude Pro, Max, or Team subscription."
echo ""
echo -e "  ${CYAN}3. Restart your terminal (or log out and back in)${RESET}"
echo "     → Needed for zsh to become the default shell."
echo "     → Open Ghostty after restarting."
echo ""
echo -e "  ${CYAN}4. Initialize Claude Code in your projects${RESET}"
echo "     cd ~/your-project"
echo "     claude /init"
echo "     → Creates a CLAUDE.md with project context."
echo ""
echo -e "  ${CYAN}5. Upload your SSH public key to GitHub (if not done during setup)${RESET}"
echo "     cat ~/.ssh/id_ed25519.pub"
echo "     → Paste it at: https://github.com/settings/keys"
echo "     → Then test with: ssh -T git@github.com"
echo ""
