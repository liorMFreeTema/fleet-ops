#!/bin/bash
set -e              # Stop immediately if any command fails
set -o pipefail     # Stop if the download fails (even if SSH is still open)

# --- Configuration ---
FILE_NAME=$1
REMOTE_IP=$2
REMOTE_DEST=$3
BUCKET_NAME="files-2026"
SSH_KEY="/root/.ssh/id_rsa_semaphore"
AWS_BIN="aws"

# --- 1. Validation ---
if [ -z "$FILE_NAME" ] || [ -z "$REMOTE_IP" ]; then
    echo "ERROR: Missing arguments. Usage: ./fetch_s3.sh <filename> <ip> <destination>"
    exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
    echo "ERROR: SSH Key not found at $SSH_KEY"
    echo "       (Did you fix the docker-compose volume map?)"
    exit 1
fi

# --- 2. Get File Size (For Progress Bar) ---
echo "Checking size of s3://$BUCKET_NAME/$FILE_NAME..."
FILE_SIZE=$($AWS_BIN s3api head-object --bucket "$BUCKET_NAME" --key "$FILE_NAME" --query ContentLength --output text)

echo "STREAMING START: $FILE_NAME ($FILE_SIZE bytes) -> avpc@$REMOTE_IP"

# --- 3. The Tunnel (S3 -> PV -> SSH) ---
# s3 cp -      : Download to standard output (RAM)
# pv -s ...    : Show progress bar and speed based on file size
# ssh ... cat  : Stream directly to file on vehicle (no temp files on EC2)

$AWS_BIN s3 cp "s3://$BUCKET_NAME/$FILE_NAME" - | \
pv -s "$FILE_SIZE" -f -i 0.1 | \
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "ubuntu@$REMOTE_IP" "cat > '$REMOTE_DEST'"

echo "SUCCESS: Transfer complete."
