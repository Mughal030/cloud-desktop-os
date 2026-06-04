#!/bin/bash
# ============================================================================
# Web Development Environment v12 — Startup Script
# Run as user (UID 1000) inside the desktop session
# ============================================================================

echo "Setting up desktop environment..."

# Desktop icons
mkdir -p ~/Desktop

cat > ~/Desktop/terminal.desktop << 'DEOF'
[Desktop Entry]
Name=Terminal
Comment=XFCE Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
Type=Application
DEOF

cat > ~/Desktop/vscode.desktop << 'DEOF'
[Desktop Entry]
Name=VS Code
Comment=Code Server
Exec=bash -c 'code-server --bind-addr 0.0.0.0:8080 --auth none'
Icon=vscode
Terminal=true
Type=Application
DEOF

chmod +x ~/Desktop/*.desktop 2>/dev/null || true

# .bashrc additions
if ! grep -q "# Web Dev Environment" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'BASHEOF'

# Web Dev Environment
export PATH="$PATH:/usr/local/bin"
alias ll='ls -la'
alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias install-extras='bash /app/scripts/install-extras.sh'
BASHEOF
fi

echo "Desktop setup complete"
