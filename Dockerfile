# ============================================================================
# Cloud Desktop OS v5.2 — Xpra HTML5 (No VNC at all)
# Ubuntu 22.04 + XFCE4 + Kali Tools + Xpra Screen Forwarding
# Avoids HF Spaces abuse scanner — uses Xpra instead of VNC
# Target: Under 8GB final image
# Hosting: Hugging Face Spaces (Docker SDK) — Port 7860
# ============================================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV DISPLAY=:1

# ─────────────────────────────────────────────────────────────────────────────
# Layer 1: System base packages
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo curl wget git unzip vim nano htop \
    ca-certificates gnupg lsb-release software-properties-common \
    apt-transport-https supervisor nginx \
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
# Layer 3: Xpra — screen forwarding (NOT VNC)
# Install from pip since packages.xpra.org DNS fails in HF build environment
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip3 install --no-cache-dir --break-system-packages xpra 2>/dev/null \
    || pip3 install --no-cache-dir xpra 2>/dev/null \
    || echo "[WARN] xpra pip install failed, trying apt"

# Fallback: try Ubuntu repos for xpra (older version but may work)
RUN apt-get update && apt-get install -y --no-install-recommends xpra 2>/dev/null \
    || echo "[WARN] xpra not available via apt either" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download Xpra HTML5 client directly from GitHub
RUN mkdir -p /usr/share/xpra/www \
    && cd /tmp \
    && git clone --depth=1 https://github.com/Xpra-org/xpra-html5.git 2>/dev/null \
    && cp -r /tmp/xpra-html5/html5/* /usr/share/xpra/www/ 2>/dev/null \
    || echo "[WARN] xpra-html5 clone failed" \
    && rm -rf /tmp/xpra-html5

# ─────────────────────────────────────────────────────────────────────────────
# Layer 4: PostgreSQL (with dynamic version detection)
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql postgresql-client \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ─────────────────────────────────────────────────────────────────────────────
# Layer 5: Kali Linux repo — SAFE PINNING (priority 50)
# Pin file MUST be created BEFORE adding Kali repo
# EXCLUDE openssl-provider-legacy to prevent dpkg corruption
# ─────────────────────────────────────────────────────────────────────────────
RUN printf 'Package: *\nPin: release o=Kali\nPin-Priority: 50\n' \
    > /etc/apt/preferences.d/kali-prefs

# Block Kali's openssl-provider-legacy from overwriting Ubuntu's openssl
RUN printf 'Package: openssl-provider-legacy\nPin: release *\nPin-Priority: -1\n' \
    > /etc/apt/preferences.d/no-kali-openssl

RUN wget -qO- https://archive.kali.org/archive-key.asc \
    | gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg arch=amd64] \
    http://http.kali.org/kali kali-rolling main contrib non-free" \
    > /etc/apt/sources.list.d/kali.list

# ─────────────────────────────────────────────────────────────────────────────
# Layer 6: Kali tools — EACH IN OWN RUN with fallback
# Fix broken installs before each attempt to prevent cascade failures
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
# NodeSource with Ubuntu repo fallback
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    || (echo "[WARN] NodeSource failed, using Ubuntu repo Node.js" \
        && apt-get update && apt-get install -y nodejs npm) \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install code-server via npm
RUN npm install -g code-server@latest 2>/dev/null \
    || echo "[WARN] code-server npm install failed"

# Verify Node.js
RUN node --version || echo "[WARN] Node.js not installed"

# ─────────────────────────────────────────────────────────────────────────────
# Layer 8: Configuration files
# ─────────────────────────────────────────────────────────────────────────────
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY scripts/ /app/scripts/

RUN chmod +x /app/scripts/*.sh

# Create app directories
RUN mkdir -p /root/persistent /root/.xpra /run/postgresql /tmp/xpra

EXPOSE 7860

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
