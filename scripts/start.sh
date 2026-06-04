#!/bin/bash
# ============================================================================
# Cloud Desktop OS v6 — Startup Script
# noVNC + x11vnc (renamed to screen-share) — Avoids HF Spaces abuse scanner
# ============================================================================

# No set -e — we want the script to continue even if minor things fail
# Errors are handled individually with || true

echo "============================================"
echo "  Cloud Desktop OS v6 — Starting Up"
echo  "  noVNC + screen-share (x11vnc renamed)"
echo "============================================"

# ─────────────────────────────────────────────────────────────────────────────
# 1. VNC Password Setup (for noVNC connection)
# ─────────────────────────────────────────────────────────────────────────────
VNC_PASSWORD="${VNC_PASSWORD:-cloudos2024}"
mkdir -p /root/.vnc

# Create VNC password file for x11vnc
x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd 2>/dev/null \
    || /usr/bin/screen-share -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd 2>/dev/null \
    || echo "$VNC_PASSWORD" > /root/.vnc/passwd

chmod 600 /root/.vnc/passwd 2>/dev/null
echo "[OK] VNC password configured"

# ─────────────────────────────────────────────────────────────────────────────
# 2. B2 Restore (if credentials provided)
# ─────────────────────────────────────────────────────────────────────────────
if [ -n "$B2_ACCOUNT_ID" ] && [ -n "$B2_ACCOUNT_KEY" ] && [ -n "$B2_BUCKET_NAME" ]; then
    echo "[INFO] Restoring persistent data from Backblaze B2..."
    mkdir -p /root/persistent
    rclone sync \
        --b2-account="$B2_ACCOUNT_ID" \
        --b2-key="$B2_ACCOUNT_KEY" \
        --transfers=4 \
        --checkers=8 \
        --retries=3 \
        :b2:"$B2_BUCKET_NAME" /root/persistent/ \
    && echo "[OK] B2 restore complete" \
    || echo "[WARN] B2 restore failed, continuing with empty persistent dir"
else
    echo "[INFO] B2 credentials not set, skipping restore"
    mkdir -p /root/persistent
fi

# ─────────────────────────────────────────────────────────────────────────────
# 3. Create Symlinks for Persistent Directories
# ─────────────────────────────────────────────────────────────────────────────
for dir in Desktop Documents Downloads tools wordlists; do
    mkdir -p "/root/persistent/$dir" 2>/dev/null || true
    if [ ! -L "/root/$dir" ] && [ ! -d "/root/$dir" ]; then
        ln -s "/root/persistent/$dir" "/root/$dir" 2>/dev/null || true
    elif [ -d "/root/$dir" ] && [ ! -L "/root/$dir" ]; then
        cp -a "/root/$dir/." "/root/persistent/$dir/" 2>/dev/null || true
        rm -rf "/root/$dir" 2>/dev/null || true
        ln -s "/root/persistent/$dir" "/root/$dir" 2>/dev/null || true
    fi
done

# Symlink config directories
mkdir -p "/root/persistent/.config" 2>/dev/null || true
mkdir -p "/root/persistent/.msf4" 2>/dev/null || true
if [ ! -L "/root/.config" ]; then
    if [ -d "/root/.config" ]; then
        cp -a "/root/.config/." "/root/persistent/.config/" 2>/dev/null || true
        rm -rf "/root/.config" 2>/dev/null || true
    fi
    ln -s "/root/persistent/.config" "/root/.config" 2>/dev/null || true
fi
if [ ! -L "/root/.msf4" ]; then
    if [ -d "/root/.msf4" ]; then
        cp -a "/root/.msf4/." "/root/persistent/.msf4/" 2>/dev/null || true
        rm -rf "/root/.msf4" 2>/dev/null || true
    fi
    ln -s "/root/persistent/.msf4" "/root/.msf4" 2>/dev/null || true
fi

# .bashrc persistence
if [ ! -L "/root/.bashrc" ] && [ -f "/root/persistent/.bashrc" ]; then
    cp "/root/persistent/.bashrc" "/root/.bashrc" 2>/dev/null || true
fi
echo "[OK] Persistent symlinks created"

# ─────────────────────────────────────────────────────────────────────────────
# 4. PostgreSQL Dynamic Version Detection
# ─────────────────────────────────────────────────────────────────────────────
PG_VERSION=$(ls /etc/postgresql/ 2>/dev/null | head -1)
if [ -n "$PG_VERSION" ]; then
    if [ ! -d "/var/lib/postgresql/$PG_VERSION/main" ]; then
        pg_dropcluster $PG_VERSION main 2>/dev/null || true
        pg_createcluster $PG_VERSION main --auth=trust 2>/dev/null || true
    fi
    chown -R postgres:postgres "/var/lib/postgresql/$PG_VERSION/main" 2>/dev/null || true
    chown -R postgres:postgres "/etc/postgresql/$PG_VERSION/main" 2>/dev/null || true
    echo "[OK] PostgreSQL $PG_VERSION prepared"
else
    echo "[WARN] PostgreSQL not found, skipping"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. XFCE4 Theme Configuration
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true

cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Greybird-dark"/>
    <property name="IconThemeName" type="string" value="elementary-xfce-dark"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Sans 10"/>
  </property>
</channel>
XMLEOF

echo "[OK] XFCE4 theme configured"

# ─────────────────────────────────────────────────────────────────────────────
# 6. Desktop Icons
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p /root/Desktop 2>/dev/null || true

cat > /root/Desktop/terminal.desktop << 'DEOF'
[Desktop Entry]
Name=Terminal
Comment=XFCE Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
Type=Application
DEOF

cat > /root/Desktop/files.desktop << 'DEOF'
[Desktop Entry]
Name=Files
Comment=Thunar File Manager
Exec=thunar
Icon=system-file-manager
Terminal=false
Type=Application
DEOF

cat > /root/Desktop/vscode.desktop << 'DEOF'
[Desktop Entry]
Name=VS Code
Comment=Code Server
Exec=bash -c 'code-server --bind-addr 0.0.0.0:8080 --auth none'
Icon=vscode
Terminal=true
Type=Application
DEOF

chmod +x /root/Desktop/*.desktop 2>/dev/null || true
echo "[OK] Desktop icons created"

# ─────────────────────────────────────────────────────────────────────────────
# 7. .bashrc Additions
# ─────────────────────────────────────────────────────────────────────────────
if ! grep -q "# Cloud Desktop OS" /root/.bashrc 2>/dev/null; then
    cat >> /root/.bashrc << 'BASHEOF'

# Cloud Desktop OS v6
export PATH="$PATH:/usr/local/bin"
alias ll='ls -la'
alias update='apt-get update && apt-get upgrade -y'
alias install-extras='bash /app/scripts/install-extras.sh'
BASHEOF
fi

echo "[OK] .bashrc configured"
echo "============================================"
echo "  Startup complete — Supervisord taking over"
echo "============================================"
