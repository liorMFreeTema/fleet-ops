#!/bin/bash
set -e
set -o pipefail

# --- Configuration ---
FILE_NAME=$1
REMOTE_IP=$2
REMOTE_DEST=$3
BUCKET_NAME="files-2026"
SSH_KEY="/root/.ssh/id_rsa_semaphore"

# --- 1. Get File Size (So we can calculate percentage) ---
# We ask S3: "How big is this file?"
FILE_SIZE=$(aws s3api head-object --bucket "$BUCKET_NAME" --key "$FILE_NAME" --query ContentLength --output text)

echo "STREAMING: $FILE_NAME ($FILE_SIZE bytes) -> $REMOTE_IP"

# --- 2. The Tunnel with Progress Bar ---
# pv -s $FILE_SIZE = "The total size is X"
# pv -n = Output numeric percentage (easier for logs)
# pv -i 1 = Update every 1 second (don't spam the logs)

aws s3 cp "s3://$BUCKET_NAME/$FILE_NAME" - | \
pv -s "$FILE_SIZE" -f -i 1 | \
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "avpc@$REMOTE_IP" "cat > '$REMOTE_DEST'"

echo "SUCCESS: Transfer complete."
