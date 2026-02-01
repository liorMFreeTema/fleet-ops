#!/bin/bash
set -e              # Exit immediately if any command fails
set -o pipefail     # Fail the whole script if the S3 download fails (not just the SSH)

# --- Configuration ---
FILE_NAME=$1
REMOTE_IP=$2
REMOTE_DEST=$3
BUCKET_NAME="files-2026"
AWS_BIN="aws"
SSH_KEY="/root/.ssh/id_rsa_semaphore"

# --- Safety Checks ---
if [ -z "$FILE_NAME" ] || [ -z "$REMOTE_IP" ]; then
    echo "ERROR: Missing arguments."
    exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
    echo "ERROR: SSH Key not found at $SSH_KEY."
    exit 1
fi

echo "STREAMING: $FILE_NAME from S3 -> $REMOTE_IP (via EC2 Tunnel)"

# --- The Tunnel (Simplified) ---
# We don't need complex if/else checks because 'set -e' handles errors automatically
$AWS_BIN s3 cp "s3://$BUCKET_NAME/$FILE_NAME" - | ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "ubuntu@$REMOTE_IP" "cat > '$REMOTE_DEST'"

echo "SUCCESS: Transfer complete."
