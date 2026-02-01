#!/bin/bash

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

# --- The Tunnel ---
# CRITICAL CHANGE: "vboxuser@" is now "ubuntu@"
$AWS_BIN s3 cp "s3://$BUCKET_NAME/$FILE_NAME" - | ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "ubuntu@$REMOTE_IP" "cat > '$REMOTE_DEST'"

if [ ${PIPESTATUS[0]} -eq 0 ] && [ ${PIPESTATUS[1]} -eq 0 ]; then
    echo "SUCCESS: Transfer complete."
    exit 0
else
    echo "FAILED: Stream broke. Check if S3 file exists."
    exit 1
fi
