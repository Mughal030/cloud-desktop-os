#!/bin/bash
# ============================================================================
# Cloud Desktop OS v5 — Interactive Extra Tools Installer
# Run: bash /app/scripts/install-extras.sh
# Installs heavier tools that are not included in the base image
# ============================================================================

echo "============================================"
echo "  Cloud Desktop OS — Extra Tools Installer"
echo "============================================"
echo ""
echo "This will install the following tools:"
echo "  1. Metasploit Framework"
echo "  2. Wireshark"
echo "  3. Aircrack-ng"
echo "  4. Burp Suite"
echo "  5. Hashcat"
echo "  6. GIMP"
echo "  7. LibreOffice"
echo "  8. ExploitDB (searchsploit)"
echo ""
read -p "Continue? [y/N] " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Installation cancelled."
    exit 0
fi

# ── Metasploit Framework ──
echo ""
echo "[1/8] Installing Metasploit Framework..."
apt-get update && apt-get install -y --no-install-recommends -t kali-rolling metasploit-framework \
    && echo "[OK] Metasploit installed" \
    || echo "[WARN] Metasploit install failed (common on non-Kali)"
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ── Wireshark ──
echo ""
echo "[2/8] Installing Wireshark..."
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections 2>/dev/null || true
apt-get update && apt-get install -y --no-install-recommends wireshark tshark \
    && echo "[OK] Wireshark installed" \
    || echo "[WARN] Wireshark install failed"
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ── Aircrack-ng ──
echo ""
echo "[3/8] Installing Aircrack-ng..."
apt-get update && apt-get install -y --no-install-recommends -t kali-rolling aircrack-ng \
    && echo "[OK] Aircrack-ng installed (WiFi tools need real hardware)" \
    || echo "[WARN] Aircrack-ng install failed"
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ── Burp Suite ──
echo ""
echo "[4/8] Installing Burp Suite..."
apt-get update && apt-get install -y --no-install-recommends -t kali-rolling burpsuite \
    && echo "[OK] Burp Suite installed" \
    || echo "[WARN] Burp Suite install failed (requires Java)"
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ── Hashcat ──
echo ""
echo "[5/8] Installing Hashcat..."
apt-get update && apt-get install -y --no-install-recommends hashcat \
    && echo "[OK] Hashcat installed (CPU mode only — no GPU on HF Spaces)" \
    || echo "[WARN] Hashcat install failed"
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ── GIMP ──
echo ""
echo "[6/8] Installing GIMP..."
apt-get update && apt-get install -y --no-install-recommends gimp \
    && echo "[OK] GIMP installed" \
    || echo "[WARN] GIMP install failed"
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ── LibreOffice ──
echo ""
echo "[7/8] Installing LibreOffice..."
apt-get update && apt-get install -y --no-install-recommends libreoffice-writer libreoffice-calc \
    && echo "[OK] LibreOffice installed" \
    || echo "[WARN] LibreOffice install failed"
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ── ExploitDB ──
echo ""
echo "[8/8] Installing ExploitDB (searchsploit)..."
apt-get update && apt-get install -y --no-install-recommends -t kali-rolling exploitdb \
    && echo "[OK] ExploitDB installed" \
    || echo "[WARN] ExploitDB install failed"
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

echo ""
echo "============================================"
echo "  Extra tools installation complete!"
echo "============================================"
