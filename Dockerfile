# ============================================================================
# Web Development Environment v10
# Based on linuxserver/webtop — proven KasmVNC + XFCE4 setup
# Adds: network analysis tools, Node.js, code-server, PostgreSQL, rclone
# Port: 7860 (proxied via nginx from linuxserver's 3000)
# ============================================================================

FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# linuxserver/webtop runs on port 3000 (HTTP) and 3001 (HTTPS)
# HF Spaces needs port 7860
# We add nginx to proxy 7860 → 3000

ENV PUID=0
ENV PGID=0
ENV TZ=UTC
ENV CUSTOM_USER=root
ENV PASSWORD=cloudos2024
ENV TITLE="Web Dev Environment"

# ─────────────────────────────────────────────────────────────────────────────
# Layer 1: Install nginx for port proxy + additional system packages
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    sudo curl wget git unzip vim nano htop \
    ca-certificates gnupg lsb-release software-properties-common \
    apt-transport-https \
    rclone openssh-client net-tools \
    postgresql postgresql-client \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ─────────────────────────────────────────────────────────────────────────────
# Layer 2: Configure nginx to proxy 7860 → 3000
# ─────────────────────────────────────────────────────────────────────────────
RUN echo 'worker_processes 1;\n\
pid /run/nginx-proxy.pid;\n\
error_log /var/log/nginx/error.log warn;\n\
\n\
events {\n\
    worker_connections 1024;\n\
}\n\
\n\
http {\n\
    sendfile on;\n\
    keepalive_timeout 65;\n\
\n\
    server {\n\
        listen 7860;\n\
        server_name _;\n\
\n\
        location / {\n\
            proxy_pass http://127.0.0.1:3000;\n\
            proxy_http_version 1.1;\n\
            proxy_set_header Upgrade $http_upgrade;\n\
            proxy_set_header Connection "upgrade";\n\
            proxy_set_header Host $host;\n\
            proxy_set_header X-Real-IP $remote_addr;\n\
            proxy_read_timeout 86400s;\n\
            proxy_send_timeout 86400s;\n\
            proxy_buffering off;\n\
        }\n\
    }\n\
}' > /etc/nginx/nginx-proxy.conf

# ─────────────────────────────────────────────────────────────────────────────
# Layer 3: Additional package repository (network tools)
# Pin priority 50 — only installs when explicitly requested
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
# Layer 4: Network analysis tools
# Each in own RUN with fallback
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
# Layer 5: Node.js + code-server
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
# Layer 6: Startup scripts
# ─────────────────────────────────────────────────────────────────────────────
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# ─────────────────────────────────────────────────────────────────────────────
# Layer 7: s6-overlay init — add nginx proxy and our startup script
# linuxserver/webtop uses s6-overlay for service management
# We add our services as s6-overlay init scripts
# ─────────────────────────────────────────────────────────────────────────────
# Add nginx proxy as an s6 service
RUN mkdir -p /etc/s6-overlay/s6-rc.d/nginx-proxy
RUN printf '#!/command/with-contenv bash\nexec nginx -c /etc/nginx/nginx-proxy.conf -g "daemon off;"\n' \
    > /etc/s6-overlay/s6-rc.d/nginx-proxy/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/nginx-proxy/run
RUN printf '3\n' > /etc/s6-overlay/s6-rc.d/nginx-proxy/notification-fd
RUN touch /etc/s6-overlay/s6-rc.d/nginx-proxy/down

# Create the bundle that enables nginx-proxy
RUN mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d/nginx-proxy

# Add our custom startup script
RUN mkdir -p /etc/s6-overlay/s6-rc.d/custom-init
RUN printf '#!/command/with-contenv bash\n/app/scripts/start.sh\n' \
    > /etc/s6-overlay/s6-rc.d/custom-init/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/custom-init/run
RUN printf '3\n' > /etc/s6-overlay/s6-rc.d/custom-init/notification-fd
RUN touch /etc/s6-overlay/s6-rc.d/custom-init/down
RUN mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d/custom-init

# Create app directories
RUN mkdir -p /root/persistent /run/postgresql

# Expose HF-required port
EXPOSE 7860
