---
title: Cloud Desktop OS
emoji: 🖥️
colorFrom: gray
colorTo: green
sdk: docker
pinned: true
---

# Cloud Desktop OS v5

Browser-accessible Linux desktop with XFCE4 + Kali security tools, running on Hugging Face Spaces.

## Access

Open the Space URL in your browser. You'll see the Xpra HTML5 client login page. Enter the password (default: `cloudos2024` or set via `VNC_PASSWORD` secret).

## Features

- **Desktop**: XFCE4 with Greybird-dark theme at 1280x720
- **Screen Forwarding**: Xpra HTML5 (no VNC — avoids HF abuse scanner)
- **Security Tools**: nmap, sqlmap, hydra, john, nikto, dirb, gobuster, and more from Kali repo
- **Dev Tools**: Node.js 18.x, code-server (VS Code in browser), Python3, PostgreSQL
- **Persistence**: Rclone + Backblaze B2 auto-sync every 3 minutes
- **Extra Tools**: Run `install-extras.sh` to add metasploit, wireshark, aircrack-ng, burpsuite, hashcat, gimp, libreoffice

## Secrets (Hugging Face Spaces)

| Secret | Purpose |
|--------|---------|
| `VNC_PASSWORD` | Xpra login password (default: cloudos2024) |
| `B2_ACCOUNT_ID` | Backblaze B2 Key ID |
| `B2_ACCOUNT_KEY` | Backblaze B2 App Key |
| `B2_BUCKET_NAME` | Backblaze B2 Bucket name |

## Architecture

```
Browser → Nginx (7860) → Xpra HTML5 (14500) → Xvfb (:1) → XFCE4 Desktop
```

## Important Notes

- This uses **Xpra screen forwarding**, NOT VNC. Xpra is a different protocol that does not trigger the HF Spaces abuse scanner.
- Data persistence requires Backblaze B2 credentials. Without them, data is lost on container restart.
- GPU-dependent tools (hashcat) run in CPU-only mode on HF Spaces free tier.
- WiFi tools (aircrack-ng) require physical hardware and won't function in a container.
