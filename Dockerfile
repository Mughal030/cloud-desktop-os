# ============================================================================
# Web Development Environment v12
# Based on proven working HF Spaces template (kenken999/novnc-openbox-light)
# Debian + XFCE4 + TigerVNC + noVNC on port 7860
# ============================================================================

FROM debian:sid

# Setup root permissions
RUN chown root:shadow /etc/shadow && chmod 640 /etc/shadow

# Create user (HF Spaces requires UID 1000)
RUN useradd -d /home/user -s /bin/bash -m -u 1000 user && \
    chown user -R /home/user && \
    echo "cd ~" > /home/user/.bashrc

# Set password for user
RUN echo 'user:cloudos2024' | chpasswd && pwconv

# Install desktop environment and remote access tools
RUN apt update && apt -y full-upgrade && \
    apt install -y --no-install-recommends \
    vim bash xfce4-terminal xfce4 xfce4-whiskermenu-plugin \
    thunar mousepad greybird-gtk-theme gtk2-engines-murrine \
    sudo curl wget git unzip nano htop \
    tigervnc-standalone-server \
    python3-websockify \
    xterm \
    rclone openssh-client net-tools \
    postgresql postgresql-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Remove screensavers
RUN apt remove -y xscreensaver-data xscreensaver 2>/dev/null || true

# Setup hostname
RUN hostname hf-server || echo 'failed to set hostname'

# Clone noVNC
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /noVNC

# Setup VNC directory
RUN mkdir -p /home/user/.vnc && \
    chmod -R 777 /home/user/.vnc /tmp && \
    echo 'cloudos2024' | vncpasswd -f > /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd

# Grant sudo permissions without password
RUN echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    groupadd -f sudo && \
    usermod -aG sudo user

# ─────────────────────────────────────────────────────────────────────────────
# Additional package repository (network analysis tools)
# ─────────────────────────────────────────────────────────────────────────────
RUN printf 'Package: *\nPin: release o=Kali\nPin-Priority: 50\n' \
    > /etc/apt/preferences.d/extra-prefs

RUN printf 'Package: openssl-provider-legacy\nPin: release *\nPin-Priority: -1\n' \
    > /etc/apt/preferences.d/no-legacy-openssl

RUN apt update && apt install -y --no-install-recommends gnupg \
    && wget -qO- https://archive.kali.org/archive-key.asc \
    | gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg arch=amd64] \
    http://http.kali.org/kali kali-rolling main contrib non-free" \
    > /etc/apt/sources.list.d/extra.list \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────────────────────────────────────
# Network analysis and development tools
# ─────────────────────────────────────────────────────────────────────────────
RUN apt update && apt -y --fix-broken install 2>/dev/null; \
    apt install -y --no-install-recommends -t kali-rolling nmap \
    || echo "[WARN] nmap install failed" \
    && rm -rf /var/lib/apt/lists/*

RUN apt update && apt -y --fix-broken install 2>/dev/null; \
    apt install -y --no-install-recommends -t kali-rolling whois \
    || echo "[WARN] whois install failed" \
    && rm -rf /var/lib/apt/lists/*

RUN apt update && apt -y --fix-broken install 2>/dev/null; \
    apt install -y --no-install-recommends -t kali-rolling sqlmap \
    || echo "[WARN] sqlmap install failed" \
    && rm -rf /var/lib/apt/lists/*

RUN apt update && apt -y --fix-broken install 2>/dev/null; \
    apt install -y --no-install-recommends -t kali-rolling hydra \
    || echo "[WARN] hydra install failed" \
    && rm -rf /var/lib/apt/lists/*

RUN apt update && apt -y --fix-broken install 2>/dev/null; \
    apt install -y --no-install-recommends -t kali-rolling john \
    || echo "[WARN] john install failed" \
    && rm -rf /var/lib/apt/lists/*

RUN apt update && apt -y --fix-broken install 2>/dev/null; \
    apt install -y --no-install-recommends -t kali-rolling nikto \
    || echo "[WARN] nikto install failed" \
    && rm -rf /var/lib/apt/lists/*

RUN apt update && apt -y --fix-broken install 2>/dev/null; \
    apt install -y --no-install-recommends -t kali-rolling dirb \
    || echo "[WARN] dirb install failed" \
    && rm -rf /var/lib/apt/lists/*

RUN apt update && apt -y --fix-broken install 2>/dev/null; \
    apt install -y --no-install-recommends -t kali-rolling gobuster \
    || echo "[WARN] gobuster install failed" \
    && rm -rf /var/lib/apt/lists/*

RUN apt update && apt -y --fix-broken install 2>/dev/null; \
    apt install -y --no-install-recommends \
    netcat-openbsd tcpdump proxychains4 \
    || echo "[WARN] Some network tools install failed" \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────────────────────────────────────
# Node.js + code-server
# ─────────────────────────────────────────────────────────────────────────────
RUN apt update && apt -y --fix-broken install 2>/dev/null; \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt install -y nodejs \
    || (apt update && apt install -y nodejs npm) \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g code-server@latest 2>/dev/null \
    || echo "[WARN] code-server npm install failed"

# ─────────────────────────────────────────────────────────────────────────────
# Startup scripts
# ─────────────────────────────────────────────────────────────────────────────
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Environment
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    DISPLAY=:1

# Expose HF Spaces required port
EXPOSE 7860

USER user
WORKDIR /home/user

# Start TigerVNC + noVNC
CMD vncserver -SecurityTypes VncAuth -rfbauth /home/user/.vnc/passwd -geometry 1280x720 && \
    /noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:7860
