#!/bin/bash
# ============================================================================
# Cloud Desktop OS — Main Startup Script
# Handles: x11vnc password, B2 restore, symlinks, dynamic PG, desktop icons
# Uses x11vnc instead of TigerVNC to avoid HF Spaces abuse detection
# ============================================================================

set -e

echo "============================================"
echo "  Cloud Desktop OS — Starting Up"
echo "============================================"

# ---------------------------------------------------------------------------
# 1. Set x11vnc Password
# x11vnc uses its own password file format, not vncpasswd
# ---------------------------------------------------------------------------
echo "[STARTUP] Configuring remote desktop password..."
VNC_PASSWORD="${VNC_PASSWORD:-cloudos2024}"

mkdir -p /root/.x11vnc

# x11vnc password file: store password in plain text for -rfbauth
# x11vnc can read a file with a single line containing the password
# Or use -passwd flag directly. We store it for -rfbauth compatibility.
x11vnc -storepasswd "$VNC_PASSWORD" /root/.x11vnc/passwd 2>/dev/null || \
    printf "%s\n" "$VNC_PASSWORD" > /root/.x11vnc/passwd
chmod 600 /root/.x11vnc/passwd

echo "[STARTUP] Remote desktop password set."

# ---------------------------------------------------------------------------
# 2. Backblaze B2 Persistence Restore
# If B2 env vars are missing → skip sync, boot normally
# ---------------------------------------------------------------------------
if [ -n "$B2_ACCOUNT_ID" ] && [ -n "$B2_ACCOUNT_KEY" ] && [ -n "$B2_BUCKET_NAME" ]; then
    echo "[STARTUP] B2 credentials found. Restoring persistent data..."
    mkdir -p /root/persistent

    # CRITICAL: Use inline env flags (NOT rclone config — files don't persist)
    rclone sync \
        :b2:"$B2_BUCKET_NAME" \
        /root/persistent/ \
        --b2-account="$B2_ACCOUNT_ID" \
        --b2-key="$B2_ACCOUNT_KEY" \
        --transfers 4 \
        --checkers 8 \
        --contimeout 60s \
        --timeout 300s \
        --retries 3 \
        2>/dev/null || echo "[WARN] B2 restore failed. Continuing with empty storage."
else
    echo "[STARTUP] No B2 credentials. Skipping cloud sync (booting normally)."
    mkdir -p /root/persistent
fi

# ---------------------------------------------------------------------------
# 3. Create persistent symlinks
# ---------------------------------------------------------------------------
echo "[STARTUP] Creating persistent directory symlinks..."

mkdir -p /root/persistent/Desktop
mkdir -p /root/persistent/Documents
mkdir -p /root/persistent/Downloads
mkdir -p /root/persistent/tools
mkdir -p /root/persistent/wordlists
mkdir -p /root/persistent/.config
mkdir -p /root/persistent/.msf4

# Symlink directories to persistent storage
for DIR in Desktop Documents Downloads tools wordlists; do
    TARGET="/root/persistent/$DIR"
    LINK="/root/$DIR"
    if [ -d "$LINK" ] && [ ! -L "$LINK" ]; then
        cp -a "$LINK/." "$TARGET/" 2>/dev/null || true
        rm -rf "$LINK"
    fi
    if [ ! -L "$LINK" ]; then
        ln -s "$TARGET" "$LINK"
    fi
done

# Symlink hidden config directories
for ITEM in .config .msf4; do
    TARGET="/root/persistent/$ITEM"
    LINK="/root/$ITEM"
    if [ -d "$LINK" ] && [ ! -L "$LINK" ]; then
        cp -a "$LINK/." "$TARGET/" 2>/dev/null || true
        rm -rf "$LINK"
    fi
    if [ ! -L "$LINK" ]; then
        ln -s "$TARGET" "$LINK"
    fi
done

# .bashrc file symlink with custom aliases
if [ ! -f /root/persistent/.bashrc ]; then
    cp /etc/skel/.bashrc /root/persistent/.bashrc 2>/dev/null || true
    cat >> /root/persistent/.bashrc << 'ALIASES'

# Cloud Desktop OS custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias update='sudo apt update && sudo apt upgrade -y'
alias ports='sudo netstat -tulanp'
alias myip='curl -s ifconfig.me'
alias weather='curl -s wttr.in'
ALIASES
fi
if [ ! -L /root/.bashrc ]; then
    rm -f /root/.bashrc
    ln -s /root/persistent/.bashrc /root/.bashrc
fi

echo "[STARTUP] Persistent symlinks created."

# ---------------------------------------------------------------------------
# 4. Dynamic PostgreSQL Setup
# Never hardcode version numbers — detect dynamically
# ---------------------------------------------------------------------------
echo "[STARTUP] Configuring PostgreSQL..."
PG_VERSION=$(ls /etc/postgresql/ 2>/dev/null | head -n1)

if [ -n "$PG_VERSION" ]; then
    echo "[STARTUP] Detected PostgreSQL version: $PG_VERSION"
    PG_DATA="/var/lib/postgresql/$PG_VERSION/main"
    if [ -d "$PG_DATA" ]; then
        chown -R postgres:postgres "$PG_DATA"
        chmod 700 "$PG_DATA"
    fi
    mkdir -p /var/run/postgresql
    chown postgres:postgres /var/run/postgresql
else
    echo "[STARTUP] No PostgreSQL installation detected. Skipping."
fi

# ---------------------------------------------------------------------------
# 5. Create Desktop Icons
# ---------------------------------------------------------------------------
echo "[STARTUP] Creating desktop shortcuts..."
DESKTOP_DIR="/root/Desktop"
mkdir -p "$DESKTOP_DIR"

# Terminal
cat > "$DESKTOP_DIR/terminal.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=Terminal
Comment=XFCE Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
Type=Application
EOF

# Firefox
cat > "$DESKTOP_DIR/firefox.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=Firefox
Comment=Browse the web
Exec=firefox-esr %u
Icon=firefox-esr
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF

# File Manager
cat > "$DESKTOP_DIR/files.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=Files
Comment=Browse files
Exec=thunar
Icon=system-file-manager
Terminal=false
Type=Application
Categories=System;FileManager;
EOF

# VS Code (code-server)
cat > "$DESKTOP_DIR/vscode.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=VS Code
Comment=Code Server in Browser
Exec=firefox-esr http://localhost:8080
Icon=vscode
Terminal=false
Type=Application
Categories=Development;IDE;
EOF

# Install Extras
cat > "$DESKTOP_DIR/install-extras.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Name=Install Extras
Comment=Install heavy tools (Metasploit, Wireshark, etc.)
Exec=xfce4-terminal -e "bash /root/install-extras.sh"
Icon=system-software-install
Terminal=true
Type=Application
Categories=System;
EOF

chmod +x "$DESKTOP_DIR"/*.desktop
echo "[STARTUP] Desktop shortcuts created."

# ---------------------------------------------------------------------------
# 6. Create runtime directories
# ---------------------------------------------------------------------------
mkdir -p /var/run/supervisor
mkdir -p /var/log/supervisor
mkdir -p /run/sshd

# Clean any stale X11 locks from previous runs
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# ---------------------------------------------------------------------------
# 7. Launch Supervisord (manages all processes by priority)
# ---------------------------------------------------------------------------
echo "[STARTUP] Launching supervisord..."
echo "============================================"
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
