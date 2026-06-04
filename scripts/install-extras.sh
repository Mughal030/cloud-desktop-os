#!/bin/bash
# ============================================================================
# Cloud Desktop OS — Install Extra Tools (Post-Boot)
# Interactive script for heavy/optional tools NOT in the Docker image
# These tools are too large for the core build (would exceed 8GB limit)
# Run this from the desktop terminal: bash /root/install-extras.sh
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Cloud Desktop OS — Extra Tools Installer${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo "These tools are NOT in the core image to stay under 8GB."
echo "Select what you need. Each tool is installed separately."
echo ""

declare -A TOOLS
TOOLS=(
    ["metasploit-framework"]="Metasploit Framework (~500MB) — Penetration testing"
    ["wireshark"]="Wireshark (~200MB) — Network protocol analyzer"
    ["aircrack-ng"]="Aircrack-ng (~50MB) — Wireless security auditing"
    ["burpsuite"]="Burp Suite Community (~300MB) — Web security testing"
    ["gimp"]="GIMP (~250MB) — Image editor"
    ["libreoffice"]="LibreOffice (~400MB) — Office suite"
    ["hashcat"]="Hashcat (~50MB) — GPU password cracker"
    ["exploitdb"]="ExploitDB / searchsploit (~200MB) — Exploit database"
)

install_tool() {
    local tool="$1"
    echo ""
    echo -e "${YELLOW}Installing: $tool${NC}"

    case "$tool" in
        metasploit-framework)
            apt-get update && apt-get install -y --no-install-recommends metasploit-framework
            msfdb init 2>/dev/null || echo "[WARN] msfdb init failed. Run manually: msfdb init"
            ;;
        wireshark)
            DEBIAN_FRONTEND=noninteractive apt-get update && \
                apt-get install -y --no-install-recommends wireshark tshark
            ;;
        aircrack-ng)
            apt-get update && apt-get install -y --no-install-recommends aircrack-ng
            ;;
        burpsuite)
            apt-get update && apt-get install -y --no-install-recommends default-jdk
            mkdir -p /root/tools/burpsuite
            wget -q "https://portswigger.net/burp/releases/download?product=community&type=Jar" \
                -O /root/tools/burpsuite/burpsuite.jar || \
                echo "[WARN] Burp download failed. Get it manually from portswigger.net"
            echo '#!/bin/bash' > /root/tools/burpsuite/run.sh
            echo 'java -jar /root/tools/burpsuite/burpsuite.jar' >> /root/tools/burpsuite/run.sh
            chmod +x /root/tools/burpsuite/run.sh
            ;;
        gimp)
            apt-get update && apt-get install -y --no-install-recommends gimp
            ;;
        libreoffice)
            apt-get update && apt-get install -y --no-install-recommends libreoffice-writer libreoffice-calc libreoffice-impress
            ;;
        hashcat)
            apt-get update && apt-get install -y --no-install-recommends hashcat
            ;;
        exploitdb)
            apt-get update && apt-get install -y --no-install-recommends exploitdb
            ;;
        *)
            echo -e "${RED}Unknown tool: $tool${NC}"
            return 1
            ;;
    esac

    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    echo -e "${GREEN}[OK]${NC} $tool installed."
}

# --- Interactive menu ---
echo -e "${YELLOW}Available tools:${NC}"
echo ""

i=1
TOOL_KEYS=()
for key in "${!TOOLS[@]}"; do
    TOOL_KEYS+=("$key")
    echo -e "  ${CYAN}$i)${NC} $key — ${TOOLS[$key]}"
    ((i++))
done

echo ""
echo -e "  ${CYAN}a)${NC} Install ALL tools"
echo -e "  ${CYAN}q)${NC} Quit without installing"
echo ""

read -p "Enter your choice(s) [e.g., 1 3 5 or 'a' for all]: " CHOICE

if [ "$CHOICE" = "q" ]; then
    echo "Exiting."
    exit 0
fi

if [ "$CHOICE" = "a" ] || [ "$CHOICE" = "A" ]; then
    echo -e "${YELLOW}Installing ALL extra tools (this will take a while)...${NC}"
    for key in "${TOOL_KEYS[@]}"; do
        install_tool "$key" || true
    done
else
    for num in $CHOICE; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#TOOL_KEYS[@]}" ]; then
            idx=$((num - 1))
            key="${TOOL_KEYS[$idx]}"
            install_tool "$key" || true
        else
            echo -e "${RED}Invalid choice: $num${NC}"
        fi
    done
fi

echo ""
echo -e "${GREEN}Extra tools installation complete!${NC}"
echo "Installed tools in /root/persistent/tools/ will persist via B2 sync."
