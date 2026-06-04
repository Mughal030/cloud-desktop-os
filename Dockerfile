# ============================================================================
# Cloud Desktop OS - Multi-Stage Docker Build
# Ubuntu 22.04 + XFCE4 + Kali Security Tools (Pinned Safe)
# Target: Under 8GB final image
# Hosting: Hugging Face Spaces (Docker SDK) — Port 7860
# ============================================================================

# ---------------------------------------------------------------------------
# STAGE 1: Builder — Download code-server via npm (keeps final image clean)
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Node.js 18.x in builder for npm install
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install code-server globally via npm
RUN npm install -g code-server@4.20.0 && \
    npm cache clean --force

# ---------------------------------------------------------------------------
# STAGE 2: Final production image
# ---------------------------------------------------------------------------
FROM ubuntu:22.04

LABEL maintainer="Cloud Desktop OS"
LABEL description="Browser-accessible Cloud Desktop — Ubuntu + XFCE4 + Security Tools"

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV HOME=/root
ENV TZ=UTC

# ===========================================================================
# Layer 1: System base packages (changes least often → cached longest)
# ===========================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo curl wget git unzip vim nano htop \
    supervisor nginx xvfb rclone \
    postgresql postgresql-client \
    openssh-server net-tools \
    ca-certificates gnupg lsb-release \
    software-properties-common apt-transport-https \
    dbus-x11 procps iputils-ping \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ===========================================================================
# Layer 2: XFCE4 Desktop environment
# ===========================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-terminal xfce4-whiskermenu-plugin \
    thunar mousepad \
    gtk2-engines gtk2-engines-murrine \
    gtk3-engines-adwaita greybird-gtk-theme \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ===========================================================================
# Layer 3: VNC + noVNC + Firefox
# ===========================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    tigervnc-standalone-server tigervnc-common \
    novnc websockify \
    firefox-esr \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ===========================================================================
# Layer 4: Kali Linux repo — ADDED SAFELY with apt preferences pin
# ===========================================================================

# STEP A: Create pin preferences BEFORE adding the Kali repo
# Pin-Priority 50 means Kali packages will NEVER override Ubuntu packages
# unless explicitly requested (e.g., apt install -t kali-rolling nmap)
RUN mkdir -p /etc/apt/preferences.d && \
    printf 'Package: *\nPin: release o=Kali\nPin-Priority: 50\n' \
    > /etc/apt/preferences.d/kali-prefs

# STEP B: Add Kali repo with proper GPG key handling
# Ubuntu 22.04 apt REQUIRES binary .gpg format (not ASCII .asc)
# Must use gpg --dearmor to convert, then reference via signed-by=
RUN mkdir -p /usr/share/keyrings && \
    wget -qO- https://archive.kali.org/archive-key.asc | \
    gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] http://http.kali.org/kali kali-rolling main contrib non-free" \
    > /etc/apt/sources.list.d/kali.list

# STEP C: Install Kali security tools — ALWAYS from Kali repo explicitly
# Never mix Ubuntu and Kali packages in the same apt install command
# Each tool installed individually with fallback so one failure doesn't kill the build
RUN apt-get update && \
    apt-get install -y --no-install-recommends -t kali-rolling nmap || apt-get install -y --no-install-recommends nmap || true && \
    apt-get install -y --no-install-recommends -t kali-rolling whois || apt-get install -y --no-install-recommends whois || true && \
    apt-get install -y --no-install-recommends -t kali-rolling dnsenum || apt-get install -y --no-install-recommends dnsenum || true && \
    apt-get install -y --no-install-recommends -t kali-rolling theharvester || apt-get install -y --no-install-recommends theharvester || true && \
    apt-get install -y --no-install-recommends -t kali-rolling sqlmap || apt-get install -y --no-install-recommends sqlmap || true && \
    apt-get install -y --no-install-recommends -t kali-rolling hydra || apt-get install -y --no-install-recommends hydra || true && \
    apt-get install -y --no-install-recommends -t kali-rolling john || apt-get install -y --no-install-recommends john || true && \
    apt-get install -y --no-install-recommends -t kali-rolling nikto || apt-get install -y --no-install-recommends nikto || true && \
    apt-get install -y --no-install-recommends -t kali-rolling dirb || apt-get install -y --no-install-recommends dirb || true && \
    apt-get install -y --no-install-recommends -t kali-rolling gobuster || apt-get install -y --no-install-recommends gobuster || true && \
    apt-get install -y --no-install-recommends -t kali-rolling whatweb || apt-get install -y --no-install-recommends whatweb || true && \
    apt-get install -y --no-install-recommends -t kali-rolling wordlists || apt-get install -y --no-install-recommends wordlists || true && \
    apt-get install -y --no-install-recommends -t kali-rolling netcat-openbsd || apt-get install -y --no-install-recommends netcat-openbsd || true && \
    apt-get install -y --no-install-recommends -t kali-rolling tcpdump || apt-get install -y --no-install-recommends tcpdump || true && \
    apt-get install -y --no-install-recommends -t kali-rolling proxychains4 || apt-get install -y --no-install-recommends proxychains4 || true && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ===========================================================================
# Layer 5: Development tools
# ===========================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv virtualenv \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Node.js 18.x from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* || \
    (echo "[WARN] NodeSource install failed, falling back to Ubuntu nodejs" && \
     apt-get update && \
     apt-get install -y --no-install-recommends nodejs npm && \
     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*)

# Install code-server from builder stage
COPY --from=builder /usr/lib/node_modules/code-server /usr/lib/node_modules/code-server
COPY --from=builder /usr/bin/code-server /usr/bin/code-server
RUN ln -sf /usr/lib/node_modules/code-server/bin/code-server /usr/bin/code-server 2>/dev/null || \
    echo "[WARN] code-server copy failed, user can install via npm later"

# ===========================================================================
# Layer 6: Configuration files (changes most often → cached shortest)
# ===========================================================================
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/start.sh /root/start.sh
COPY scripts/auto-sync.sh /root/auto-sync.sh
COPY scripts/install-extras.sh /root/install-extras.sh

RUN chmod +x /root/start.sh /root/auto-sync.sh /root/install-extras.sh

# ===========================================================================
# Layer 7: Final setup — directories, theme, VNC config
# ===========================================================================
RUN mkdir -p \
    /root/.vnc \
    /root/.config \
    /root/Desktop \
    /root/Documents \
    /root/Downloads \
    /root/tools \
    /root/persistent \
    /run/sshd \
    /var/run/supervisor \
    /var/log/supervisor \
    && \
    printf '<?xml version="1.0" encoding="UTF-8"?>\n<channel name="xsettings" version="1.0">\n  <property name="Net" type="empty">\n    <property name="ThemeName" type="string" value="Greybird-dark"/>\n  </property>\n</channel>\n' \
    > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml \
    && \
    printf '#!/bin/bash\nexport DISPLAY=:1\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startxfce4\n' \
    > /root/.vnc/xstartup \
    && chmod 755 /root/.vnc/xstartup \
    && touch /root/.vnc/passwd

EXPOSE 7860

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1

ENTRYPOINT ["/root/start.sh"]
