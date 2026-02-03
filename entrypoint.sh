#!/bin/bash
set -e

# Cleanup function
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "${RUNNER_TOKEN}"
}
trap cleanup EXIT

# Fix Docker socket permissions
if [ -S /var/run/docker.sock ]; then
    DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
    echo "Docker socket found with GID: $DOCKER_SOCK_GID"

    # Create docker group with the same GID as the socket
    if ! getent group "$DOCKER_SOCK_GID" > /dev/null 2>&1; then
        sudo groupadd -g "$DOCKER_SOCK_GID" docker
    fi

    # Add runner user to the docker group
    sudo usermod -aG "$DOCKER_SOCK_GID" runner
    echo "Added runner user to docker group (GID: $DOCKER_SOCK_GID)"
fi

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
