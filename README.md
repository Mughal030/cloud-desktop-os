---
title: Cloud Desktop OS
emoji: 🖥️
colorFrom: gray
colorTo: green
sdk: docker
pinned: true
---

# 🖥️ Cloud Desktop OS

A permanent, browser-accessible cloud desktop built on **Ubuntu 22.04 + XFCE4 + Kali Linux security tools**. Get a full Linux desktop in your browser, powered by Hugging Face Spaces.

## ✨ Features

- **Full Linux Desktop** — XFCE4 with Greybird-dark theme in your browser
- **Kali Security Tools** — Nmap, SQLMap, Hydra, John, Nikto, and more
- **Development Ready** — Python3, Node.js 18, code-server (VS Code in browser)
- **Persistent Storage** — Backblaze B2 via Rclone keeps files across restarts
- **Auto-Sync** — Files sync to B2 every 3 minutes
- **Firefox ESR** — Browse the web from your cloud desktop

## 🚀 Quick Start

1. **Fork or clone this Space**
2. **Set Secrets** in Space Settings → Variables and secrets:
   - `VNC_PASSWORD` — Your VNC password (default: `cloudos2024`)
   - `B2_ACCOUNT_ID` — Backblaze B2 Account ID (optional)
   - `B2_ACCOUNT_KEY` — Backblaze B2 Application Key (optional)
   - `B2_BUCKET_NAME` — Backblaze B2 Bucket Name (optional)
3. **Wait for build** (~5-10 min first time)
4. **Open the Space URL** → full desktop in your browser

## 🔧 Pre-Installed Core Tools

| Category | Tools |
|----------|-------|
| **Desktop** | XFCE4, Firefox ESR, Thunar, Terminal, Mousepad |
| **Security** | Nmap, SQLMap, Hydra, John, Nikto, Dirb, Gobuster, WhatWeb, DNSenum, theHarvester, Whois, Netcat, TCPDump, Proxychains4 |
| **Dev** | Python3, Node.js 18, code-server, Git |
| **System** | PostgreSQL, SSH, Vim, Nano, Htop, Rclone |

## 📦 Optional Tools (Post-Boot)

Double-click **"Install Extras"** on the desktop to install:
- Metasploit Framework, Wireshark, Aircrack-ng, Burp Suite
- GIMP, LibreOffice, Hashcat, ExploitDB

## 💾 Persistence with Backblaze B2

Without B2, files are lost on restart. To enable persistence:

1. Create a [Backblaze B2](https://www.backblaze.com/b2) account
2. Create a bucket and application key
3. Set `B2_ACCOUNT_ID`, `B2_ACCOUNT_KEY`, `B2_BUCKET_NAME` as Space secrets

Synced folders: Desktop, Documents, Downloads, tools, wordlists, .config, .msf4, .bashrc

## 🏗️ Architecture

```
Browser → Nginx (7860) → noVNC/Websockify (6080) → TigerVNC (5901) → XFCE4
                                                        ↑
                                                     Xvfb (:1)
                                                        ↑
                                                Supervisord
                                                        ↑
                           PostgreSQL + SSH + Auto-sync (B2 via Rclone)
```

## ⚠️ Notes

- Default VNC password: `cloudos2024` — change it via `VNC_PASSWORD` secret
- Free HF Spaces have limited CPU/RAM — heavy tools may run slowly
- Kali repo is pinned at priority 50 — Ubuntu packages always take precedence

## 📄 License

MIT — For educational and authorized security testing only.
