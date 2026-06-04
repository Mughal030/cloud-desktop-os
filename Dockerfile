# ============================================================================
# Web Development Environment v11
# Ubuntu 22.04 + XFCE4 + KasmVNC + Dev Tools
# Supervisord-based init — simple, no s6-overlay
# CMD starts supervisord which manages all services
# Architecture: Browser → KasmVNC (7860) → XFCE4 Desktop
# ============================================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV HOME=/root
ENV DISPLAY=:1

# ─────────────────────────────────────────────────────────────────────────────
# Layer 1: System base packages + supervisord
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo curl wget git unzip vim nano htop \
    ca-certificates gnupg lsb-release software-properties-common \
    apt-transport-https supervisor \
    rclone openssh-client net-tools dbus-x11 x11-utils \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ─────────────────────────────────────────────────────────────────────────────
# Layer 2: XFCE4 desktop (lightweight)
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-terminal xfce4-whiskermenu-plugin \
    thunar mousepad greybird-gtk-theme gtk2-engines-murrine \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ─────────────────────────────────────────────────────────────────────────────
# Layer 3: KasmVNC — web-based remote access tool
# KasmVNC includes Xvnc display server — no separate Xvfb needed
# ─────────────────────────────────────────────────────────────────────────────
# Install KasmVNC dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxfont2 libxdamage1 libxrandr2 libxcomposite1 libxshmfence1 \
    libgomp1 libjpeg-turbo8 libpulse0 \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install KasmVNC v1.4.0
RUN wget -q "https://github.com/kasmtech/KasmVNC/releases/download/v1.4.0/kasmvncserver_jammy_1.4.0_amd64.deb" \
        -O /tmp/kasmvnc.deb \
    && apt-get update \
    && apt-get install -y /tmp/kasmvnc.deb \
    && echo "[OK] KasmVNC v1.4.0 installed" \
    && rm -f /tmp/kasmvnc.deb \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add root to ssl-cert group (required by KasmVNC)
RUN adduser root ssl-cert 2>/dev/null || true

# Create KasmVNC system config — port 7860
RUN mkdir -p /etc/kasmvnc
COPY kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml

# ─────────────────────────────────────────────────────────────────────────────
# Layer 4: PostgreSQL
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql postgresql-client \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ─────────────────────────────────────────────────────────────────────────────
# Layer 5: Additional package repository (network tools)
# ─────────────────────────────────────────────────────────────────────────────
RUN printf 'Package: *\nPin: release o=Kali\nPin-Priority: 50\n' \
    > /etc/apt/preferences.d/extra-prefs

RUN printf 'Package: openssl-provider-legacy\nPin: release *\nPin-Priority: -1\n' \
    > /etc/apt/preferences.d/no-legacy-openssl

RUN wget -qO- https://archive.kali.org/archive-key.asc \
    | gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg arch=amd64] \
    http://http.kali.org/kali kali-rolling main contrib non-free" \
    > /etc/apt/sources.list.d/extra.list

# ─────────────────────────────────────────────────────────────────────────────
# Layer 6: Network analysis tools
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling nmap \
    || echo "[WARN] nmap install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling whois \
    || echo "[WARN] whois install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling sqlmap \
    || echo "[WARN] sqlmap install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling hydra \
    || echo "[WARN] hydra install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling john \
    || echo "[WARN] john install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling nikto \
    || echo "[WARN] nikto install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling dirb \
    || echo "[WARN] dirb install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling gobuster \
    || echo "[WARN] gobuster install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling dnsenum \
    || echo "[WARN] dnsenum install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling theharvester \
    || echo "[WARN] theharvester install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling whatweb \
    || echo "[WARN] whatweb install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends \
    netcat-openbsd tcpdump proxychains4 \
    || echo "[WARN] Some network tools install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    apt-get install -y --no-install-recommends -t kali-rolling wordlists \
    || echo "[WARN] wordlists install failed" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ─────────────────────────────────────────────────────────────────────────────
# Layer 7: Node.js + code-server
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get -y --fix-broken install 2>/dev/null; \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    || (echo "[WARN] NodeSource failed, using Ubuntu repo" \
        && apt-get update && apt-get install -y nodejs npm) \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN npm install -g code-server@latest 2>/dev/null \
    || echo "[WARN] code-server npm install failed"

# ─────────────────────────────────────────────────────────────────────────────
# Layer 8: Configuration files
# ─────────────────────────────────────────────────────────────────────────────
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Create required directories
RUN mkdir -p /root/persistent /run/postgresql /root/.vnc /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix

EXPOSE 7860

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
