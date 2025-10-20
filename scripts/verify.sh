#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if command -v session-manager-plugin >/dev/null 2>&1; then
    echo "AWS session-manager-plugin is already installed. Skipping install."
    session-manager-plugin --version
    echo "AWS_SESSION_MANAGER_PREINSTALLED=true" >> "$GITHUB_OUTPUT"
    exit 0
fi

echo "AWS_SESSION_MANAGER_PREINSTALLED=false" >> "$GITHUB_OUTPUT"