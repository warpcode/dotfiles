#!/bin/bash
# .chezmoiscripts/run_after_ssh-permissions.sh
# This script ensures that SSH keys have the correct permissions.
# It runs after chezmoi has applied changes.

set -euo pipefail

SSH_DIR="$HOME/.ssh"

if [ -d "$SSH_DIR" ]; then
    # Secure private keys (0600)
    # We target files starting with id_ that don't end in .pub
    find "$SSH_DIR" -type f -name 'id_*' ! -name '*.pub' -exec chmod 600 {} +
    
    # Secure public keys (0644)
    find "$SSH_DIR" -type f -name 'id_*.pub' -exec chmod 644 {} +
fi
