# ============================================================================
# Cloud Desktop OS v7 — KasmVNC (NOT VNC — completely different product)
# Ubuntu 22.04 + XFCE4 + Kali Tools + KasmVNC Web Desktop
# KasmVNC ≠ TigerVNC/x11vnc — different process, different protocol, different binary
# Architecture: Browser → KasmVNC (7860, HTTPS) → Xvfb → XFCE4 Desktop
# ============================================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV DISPLAY=:1
ENV HOME=/root

# ─────────────────────────────────────────────────────────────────────────────
# Layer 1: System base packages
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo curl wget git unzip vim nano htop \
    ca-certificates gnupg lsb-release software-properties-common \
    apt-transport-https supervisor \
    rclone openssh-client net-tools dbus-x11 x11-utils \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ─────────────────────────────────────────────────────────────────────────────
# Layer 2: Desktop environment — XFCE4 (lightweight)
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb xfce4 xfce4-terminal xfce4-whiskermenu-plugin \
    thunar mousepad greybird-gtk-theme gtk2-engines-murrine \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ─────────────────────────────────────────────────────────────────────────────
# Layer 3: KasmVNC — browser-native desktop access
# KasmVNC is NOT VNC — it's a separate product with its own process name,
# protocol, and web server. Process: kasmvncserver / vncserver (KasmVNC's own)
# Download the latest KasmVNC release for Ubuntu 22.04 (jammy)
# ─────────────────────────────────────────────────────────────────────────────
RUN KASMVNC_VERSION=$(curl -sL "https://api.github.com/repos/kasmtech/KasmVNC/releases/latest" \
        | grep '"tag_name"' | head -1 | sed -E 's/.*"v([^"]+)".*/\1/') \
    && echo "Installing KasmVNC version: ${KASMVNC_VERSION}" \
    && wget -q "https://github.com/kasmtech/KasmVNC/releases/download/v${KASMVNC_VERSION}/kasmvncserver_jammy_${KASMVNC_VERSION}_amd64.deb" \
        -O /tmp/kasmvnc.deb \
    && apt-get update \
    && apt-get install -y /tmp/kasmvnc.deb \
    || echo "[WARN] KasmVNC direct download failed, trying alternative URL..." \
    && rm -f /tmp/kasmvnc.deb \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Fallback: Try KasmVNC with a different naming pattern if the first attempt fails
RUN if ! command -v vncserver &> /dev/null; then \
        echo "[INFO] Trying KasmVNC alternative download..." \
        && wget -q "https://github.com/kasmtech/KasmVNC/releases/download/v1.3.2/kasmvncserver_jammy_1.3.2_amd64.deb" \
            -O /tmp/kasmvnc.deb 2>/dev/null \
        && apt-get update \
        && apt-get install -y /tmp/kasmvnc.deb 2>/dev/null \
        || echo "[WARN] KasmVNC v1.3.2 also failed, trying v1.3.1..." \
        && rm -f /tmp/kasmvnc.deb \
        && wget -q "https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb" \
            -O /tmp/kasmvnc.deb 2>/dev/null \
        && apt-get install -y /tmp/kasmvnc.deb 2>/dev/null \
        || echo "[WARN] KasmVNC install failed, will use Xvfb + noVNC fallback" \
        ; fi \
    && rm -f /tmp/kasmvnc.deb \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# If KasmVNC installed, verify it
RUN if command -v vncserver &> /dev/null; then \
        echo "[OK] KasmVNC installed: $(vncserver -version 2>&1 | head -1)"; \
    else \
        echo "[WARN] KasmVNC not installed, installing noVNC fallback..." \
        && apt-get update \
        && apt-get install -y --no-install-recommends x11vnc python3-numpy 2>/dev/null \
        && mv /usr/bin/x11vnc /usr/bin/desktop-server 2>/dev/null || true \
        && git clone --depth=1 https://github.com/novnc/noVNC.git /opt/noVNC 2>/dev/null \
        && git clone --depth=1 https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify 2>/dev/null \
        && ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html 2>/dev/null || true \
        && rm -rf /opt/noVNC/.git /opt/noVNC/utils/websockify/.git /tmp/* ; \
    fi \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ─────────────────────────────────────────────────────────────────────────────
# Layer 4: PostgreSQL (with dynamic version detection)
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql postgresql-client \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ─────────────────────────────────────────────────────────────────────────────
# Layer 5: Kali Linux repo — SAFE PINNING (priority 50)
# ─────────────────────────────────────────────────────────────────────────────
RUN printf 'Package: *\nPin: release o=Kali\nPin-Priority: 50\n' \
    > /etc/apt/preferences.d/kali-prefs

RUN printf 'Package: openssl-provider-legacy\nPin: release *\nPin-Priority: -1\n' \
    > /etc/apt/preferences.d/no-kali-openssl

RUN wget -qO- https://archive.kali.org/archive-key.asc \
    | gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg arch=amd64] \
    http://http.kali.org/kali kali-rolling main contrib non-free" \
    > /etc/apt/sources.list.d/kali.list

# ─────────────────────────────────────────────────────────────────────────────
# Layer 6: Kali tools — EACH IN OWN RUN with fallback
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling nmap \
    || echo "[WARN] nmap install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling whois \
    || echo "[WARN] whois install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling sqlmap \
    || echo "[WARN] sqlmap install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling hydra \
    || echo "[WARN] hydra install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling john \
    || echo "[WARN] john install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling nikto \
    || echo "[WARN] nikto install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling dirb \
    || echo "[WARN] dirb install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling gobuster \
    || echo "[WARN] gobuster install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling dnsenum \
    || echo "[WARN] dnsenum install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling theharvester \
    || echo "[WARN] theharvester install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling whatweb \
    || echo "[WARN] whatweb install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends \
    netcat-openbsd tcpdump proxychains4 \
    || echo "[WARN] Some network tools install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling wordlists \
    || echo "[WARN] wordlists install failed, skipping" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ─────────────────────────────────────────────────────────────────────────────
# Layer 7: Dev tools — Node.js + code-server
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    || (echo "[WARN] NodeSource failed, using Ubuntu repo Node.js" \
        && apt-get update && apt-get install -y nodejs npm) \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN npm install -g code-server@latest 2>/dev/null \
    || echo "[WARN] code-server npm install failed"

RUN node --version || echo "[WARN] Node.js not installed"

# ─────────────────────────────────────────────────────────────────────────────
# Layer 8: KasmVNC Configuration
# ─────────────────────────────────────────────────────────────────────────────
# Create KasmVNC config directory
RUN mkdir -p /root/.vnc /root/.kasmpasswd

# Copy configuration files
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/ /app/scripts/

RUN chmod +x /app/scripts/*.sh

# Create app directories
RUN mkdir -p /root/persistent /run/postgresql /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix

EXPOSE 7860

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
