#!/bin/bash
# ============================================================================
# Web Development Environment — Startup Script
# KasmVNC-based web workspace
# ============================================================================

# No set -e — continue even if minor things fail

echo "============================================"
echo "  Web Dev Environment — Starting Up"
echo "============================================"

# ─────────────────────────────────────────────────────────────────────────────
# 1. KasmVNC Configuration
# ─────────────────────────────────────────────────────────────────────────────
APP_PASSWORD="${APP_PASSWORD:-cloudos2024}"
mkdir -p /root/.vnc

# Create KasmVNC YAML config — THIS IS THE KEY CONFIG
# Port 7860 is required by Hugging Face Spaces
cat > /root/.vnc/kasmvnc.yaml << 'KASMEOF'
network:
  protocol: http
  interface: 0.0.0.0
  websocket_port: 7860
  use_ipv4: true
  use_ipv6: false
  ssl:
    require_ssl: false
  udp:
    public_ip: auto
desktop:
  resolution:
    width: 1280
    height: 720
  allow_resize: true
encoding:
  max_frame_rate: 30
  video_encoding:
    video_encoding_mode: always
security:
  brute_force_protection:
    blacklist_threshold: 5
    blacklist_timeout: 10
server:
  ipv6: false
KASMEOF

# Also create the system-level config
mkdir -p /etc/kasmvnc 2>/dev/null
cp /root/.vnc/kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml 2>/dev/null || true

# Set KasmVNC user password using kasmvncpasswd
if command -v kasmvncpasswd &> /dev/null; then
    echo -e "$APP_PASSWORD\n$APP_PASSWORD" | kasmvncpasswd -u root -w 2>/dev/null \
        || echo "[WARN] kasmvncpasswd failed, will use no-auth mode"
fi

# Also try vncpasswd
if command -v vncpasswd &> /dev/null; then
    echo -e "$APP_PASSWORD\n$APP_PASSWORD\nn" | vncpasswd 2>/dev/null || true
fi

echo "[OK] KasmVNC configured on port 7860"

# ─────────────────────────────────────────────────────────────────────────────
# 2. Cloud Storage Restore (if credentials provided)
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
    || echo "[WARN] Cloud restore failed, continuing with empty dir"
else
    echo "[INFO] Cloud credentials not set, skipping restore"
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

mkdir -p "/root/persistent/.config" 2>/dev/null || true
if [ ! -L "/root/.config" ]; then
    if [ -d "/root/.config" ]; then
        cp -a "/root/.config/." "/root/persistent/.config/" 2>/dev/null || true
        rm -rf "/root/.config" 2>/dev/null || true
    fi
    ln -s "/root/persistent/.config" "/root/.config" 2>/dev/null || true
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
echo "  Startup complete — Supervisord taking over"
echo "============================================"
