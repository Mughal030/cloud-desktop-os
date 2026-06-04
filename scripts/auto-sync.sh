#!/bin/bash
# ============================================================================
# Cloud Desktop OS — Auto-Sync Script
# Syncs /root/persistent/ to Backblaze B2 every 3 minutes
# Uses inline environment variable flags (NOT rclone config file)
# If B2 secrets are missing → skip sync, system still runs normally
# ============================================================================

SYNC_INTERVAL=180  # 3 minutes

echo "[AUTO-SYNC] Daemon started (interval: ${SYNC_INTERVAL}s)"

# Wait for system to fully boot before first sync
sleep 30

while true; do
    # If B2 credentials are missing, just sleep and skip
    if [ -z "$B2_ACCOUNT_ID" ] || [ -z "$B2_ACCOUNT_KEY" ] || [ -z "$B2_BUCKET_NAME" ]; then
        echo "[AUTO-SYNC] B2 credentials not configured. Sleeping ${SYNC_INTERVAL}s..."
        sleep "$SYNC_INTERVAL"
        continue
    fi

    echo "[AUTO-SYNC] Syncing /root/persistent/ → B2:$B2_BUCKET_NAME ..."

    # CRITICAL: Use inline env flags, NOT rclone config (config files don't persist)
    rclone sync \
        /root/persistent/ \
        :b2:"$B2_BUCKET_NAME" \
        --b2-account="$B2_ACCOUNT_ID" \
        --b2-key="$B2_ACCOUNT_KEY" \
        --transfers 4 \
        --checkers 8 \
        --contimeout 60s \
        --timeout 300s \
        --retries 3 \
        2>/dev/null

    if [ $? -eq 0 ]; then
        echo "[AUTO-SYNC] Sync completed successfully."
    else
        echo "[AUTO-SYNC] Sync failed. Will retry in ${SYNC_INTERVAL}s."
    fi

    sleep "$SYNC_INTERVAL"
done
