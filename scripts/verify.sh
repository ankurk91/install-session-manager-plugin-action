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

# Detect the target platform here rather than in install.sh, because the cache
# key has to distinguish .deb from .rpm before the cache step runs.
detect_arch() {
    case $(uname -m) in
        x86_64|amd64)
            echo "64bit"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "Error: Unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

detect_os() {
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    case "$ID" in
      amzn|rhel|centos|fedora)
      echo "amazon"
      ;;
      ubuntu|debian)
       echo "ubuntu"
       ;;
      *)
        echo "Error: Unsupported OS: $ID" >&2;
        exit 1
        ;;
    esac
  else
    echo "Error: Could not detect OS" >&2
    exit 1
  fi
}

# Assign first so that a detection failure aborts the step; a failing command
# substitution inside `echo` would not.
OS=$(detect_os)
ARCH=$(detect_arch)

{
  echo "AWS_SESSION_MANAGER_OS=$OS"
  echo "AWS_SESSION_MANAGER_ARCH=$ARCH"
} >> "$GITHUB_OUTPUT"
