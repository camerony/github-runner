#!/bin/bash
set -e

# Cleanup function
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "${RUNNER_TOKEN}"
}
trap cleanup EXIT

# Configure runner
./config.sh \
    --url https://github.com/camerony/Affine-custom \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "self-hosted,linux,x64,docker" \
    --work _work \
    --unattended \
    --replace

# Run runner
./run.sh
