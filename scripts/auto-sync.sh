#!/bin/bash
# ============================================================================
# Cloud Desktop OS v5 — Auto-Sync Script
# Rclone bidirectional sync with Backblaze B2 every 3 minutes
# Uses INLINE env flags (no rclone config file)
# Gracefully skips if B2 credentials are not configured
# ============================================================================

set -e

echo "[SYNC] Auto-sync service started (3-minute interval)"

# Graceful shutdown handler — sync one last time before exit
trap 'echo "[SYNC] SIGTERM received, final sync..."; sync_up; exit 0' SIGTERM SIGINT

sync_up() {
    if [ -z "$B2_ACCOUNT_ID" ] || [ -z "$B2_ACCOUNT_KEY" ] || [ -z "$B2_BUCKET_NAME" ]; then
        return 0  # Skip silently if no B2 config
    fi

    rclone sync /root/persistent/ :b2:"$B2_BUCKET_NAME" \
        --b2-account="$B2_ACCOUNT_ID" \
        --b2-key="$B2_ACCOUNT_KEY" \
        --transfers=4 \
        --checkers=8 \
        --retries=3 \
        2>/dev/null && echo "[SYNC] Upload complete" || echo "[SYNC] Upload failed"
}

sync_down() {
    if [ -z "$B2_ACCOUNT_ID" ] || [ -z "$B2_ACCOUNT_KEY" ] || [ -z "$B2_BUCKET_NAME" ]; then
        return 0
    fi

    rclone sync :b2:"$B2_BUCKET_NAME" /root/persistent/ \
        --b2-account="$B2_ACCOUNT_ID" \
        --b2-key="$B2_ACCOUNT_KEY" \
        --transfers=4 \
        --checkers=8 \
        --retries=3 \
        2>/dev/null && echo "[SYNC] Download complete" || echo "[SYNC] Download failed"
}

# Main loop
while true; do
    sleep 180  # 3 minutes
    sync_up
done
