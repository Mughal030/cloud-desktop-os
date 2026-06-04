#!/bin/bash
# ============================================================================
# Web Development Environment v10 — Startup Script
# Based on linuxserver/webtop — KasmVNC is pre-configured
# This script just handles our custom additions (persistence, DB, etc.)
# ============================================================================

echo "============================================"
echo "  Web Dev Environment — Custom Init"
echo "============================================"

# ─────────────────────────────────────────────────────────────────────────────
# 1. Cloud Storage Restore (if credentials provided)
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
# 2. Create Symlinks for Persistent Directories
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
# 3. PostgreSQL Dynamic Version Detection
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
# 4. Desktop Icons
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p /root/Desktop 2>/dev/null || true
mkdir -p /config/Desktop 2>/dev/null || true

for DESKTOP_DIR in /root/Desktop /config/Desktop; do
    cat > "$DESKTOP_DIR/terminal.desktop" << 'DEOF'
[Desktop Entry]
Name=Terminal
Comment=XFCE Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
Type=Application
DEOF

    cat > "$DESKTOP_DIR/vscode.desktop" << 'DEOF'
[Desktop Entry]
Name=VS Code
Comment=Code Server
Exec=bash -c 'code-server --bind-addr 0.0.0.0:8080 --auth none'
Icon=vscode
Terminal=true
Type=Application
DEOF

    chmod +x "$DESKTOP_DIR"/*.desktop 2>/dev/null || true
done

echo "[OK] Desktop icons created"

# ─────────────────────────────────────────────────────────────────────────────
# 5. .bashrc Additions
# ─────────────────────────────────────────────────────────────────────────────
for BASHRC in /root/.bashrc /config/.bashrc; do
    if [ -f "$BASHRC" ] && ! grep -q "# Web Dev Environment" "$BASHRC" 2>/dev/null; then
        cat >> "$BASHRC" << 'BASHEOF'

# Web Dev Environment
export PATH="$PATH:/usr/local/bin"
alias ll='ls -la'
alias update='apt-get update && apt-get upgrade -y'
alias install-extras='bash /app/scripts/install-extras.sh'
BASHEOF
    fi
done

echo "[OK] .bashrc configured"
echo "============================================"
echo "  Custom init complete"
echo "============================================"
