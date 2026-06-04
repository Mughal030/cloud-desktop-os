---
title: Web Dev Environment
emoji: 💻
colorFrom: blue
colorTo: indigo
sdk: docker
pinned: true
---

# Web Development Environment

Browser-accessible Ubuntu workspace with XFCE4 for coding, testing, and development.

## Access

Open the Space URL in your browser. Enter the password when prompted (default: `cloudos2024` or set via `APP_PASSWORD` secret).

## Features

- **Desktop**: XFCE4 with dark theme at 1280x720
- **Web Access**: Browser-based workspace via KasmVNC
- **Dev Tools**: Node.js 18.x, code-server (VS Code in browser), Python3, PostgreSQL
- **Network Tools**: nmap, sqlmap, netcat, and other development utilities
- **Persistence**: Rclone + Backblaze B2 auto-sync every 3 minutes

## Secrets

| Secret | Purpose |
|--------|---------|
| `APP_PASSWORD` | Workspace login password (default: cloudos2024) |
| `B2_ACCOUNT_ID` | Backblaze B2 Key ID |
| `B2_ACCOUNT_KEY` | Backblaze B2 App Key |
| `B2_BUCKET_NAME` | Backblaze B2 Bucket name |

## Architecture

```
Browser → KasmVNC (7860) → Xvfb :1 → XFCE4
```
