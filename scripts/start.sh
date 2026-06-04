#!/bin/bash
# ============================================================================
# Web Development Environment v11 — Startup Script
# Supervisord + KasmVNC with YAML config
# ============================================================================

echo "============================================"
echo "  Web Dev Environment — Starting Up"
echo "============================================"

# ─────────────────────────────────────────────────────────────────────────────
# 1. KasmVNC Password Setup
# ─────────────────────────────────────────────────────────────────────────────
APP_PASSWORD="${APP_PASSWORD:-cloudos2024}"
mkdir -p /root/.vnc

# Copy system KasmVNC config to user directory (user config overrides system)
cp /etc/kasmvnc/kasmvnc.yaml /root/.vnc/kasmvnc.yaml 2>/dev/null || true

# Set KasmVNC password using kasmvncpasswd
if command -v kasmvncpasswd &> /dev/null; then
    echo -e "$APP_PASSWORD\n$APP_PASSWORD" | kasmvncpasswd -u root -w 2>/dev/null \
        || echo "[WARN] kasmvncpasswd failed — will use no-password mode"
fi

# Also try vncpasswd for the display password
if command -v vncpasswd &> /dev/null; then
    echo -e "$APP_PASSWORD\n$APP_PASSWORD\nn" | vncpasswd 2>/dev/null || true
fi

echo "[OK] KasmVNC password configured"

# ─────────────────────────────────────────────────────────────────────────────
# 2. Cloud Storage Restore
# ─────────────────────────────────────────────────────────────────────────────
if [ -n "$B2_ACCOUNT_ID" ] && [ -n "$B2_ACCOUNT_KEY" ] && [ -n "$B2_BUCKET_NAME" ]; then
    echo "[INFO] Restoring data from cloud storage..."
    mkdir -p /root/persistent
    rclone sync \
        --b2-account="$B2_ACCOUNT_ID" \
        --b2-key="$B2_ACCOUNT_KEY" \
        --transfers=4 \
        --checkers=8 \
        --retries=3 \
        :b2:"$B2_BUCKET_NAME" /root/persistent/ \
    && echo "[OK] Cloud restore complete" \
    || echo "[WARN] Cloud restore failed"
else
    mkdir -p /root/persistent
fi

# ─────────────────────────────────────────────────────────────────────────────
# 3. Create Symlinks for Persistent Directories
# ─────────────────────────────────────────────────────────────────────────────
for dir in tools wordlists; do
    mkdir -p "/root/persistent/$dir" 2>/dev/null || true
    if [ ! -L "/root/$dir" ] && [ ! -d "/root/$dir" ]; then
        ln -s "/root/persistent/$dir" "/root/$dir" 2>/dev/null || true
    elif [ -d "/root/$dir" ] && [ ! -L "/root/$dir" ]; then
        cp -a "/root/$dir/." "/root/persistent/$dir/" 2>/dev/null || true
        rm -rf "/root/$dir" 2>/dev/null || true
        ln -s "/root/persistent/$dir" "/root/$dir" 2>/dev/null || true
    fi
done

echo "[OK] Persistent symlinks created"

# ─────────────────────────────────────────────────────────────────────────────
# 4. PostgreSQL Setup
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
    echo "[WARN] PostgreSQL not found"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. Desktop Configuration
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
echo "[OK] Desktop configured"

# ─────────────────────────────────────────────────────────────────────────────
# 6. .bashrc Additions
# ─────────────────────────────────────────────────────────────────────────────
if ! grep -q "# Web Dev Environment" /root/.bashrc 2>/dev/null; then
    cat >> /root/.bashrc << 'BASHEOF'

# Web Dev Environment
export PATH="$PATH:/usr/local/bin"
alias ll='ls -la'
alias update='apt-get update && apt-get upgrade -y'
alias install-extras='bash /app/scripts/install-extras.sh'
BASHEOF
fi

echo "[OK] .bashrc configured"
echo "============================================"
echo "  Startup complete"
echo "============================================"
