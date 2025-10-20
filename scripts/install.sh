#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "::debug::CACHE_ENABLED=$CACHE_ENABLED"
echo "::debug::CACHE_HIT=$CACHE_HIT"
echo "::debug::CACHE_PATH=$CACHE_PATH"

# Create and enter temporary directory
mkdir -p "$CACHE_PATH"
cd "$CACHE_PATH"

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

ARCH=$(detect_arch)
OS=$(detect_os)
REMOTE_URL_BASE="https://s3.amazonaws.com/session-manager-downloads/plugin/latest"

download_plugin() {
  echo "Downloading for $OS/$ARCH..."

  if [ "$OS" = "ubuntu" ]; then
    URL="${REMOTE_URL_BASE}/ubuntu_${ARCH}/session-manager-plugin.deb"
  else
    URL="${REMOTE_URL_BASE}/linux_${ARCH}/session-manager-plugin.rpm"
  fi

  curl -sfL \
    --retry 3 \
    --retry-delay 5 \
    --connect-timeout 15 \
    --max-time 60 \
    -O "$URL"
}

install_plugin() {
  echo "Installing plugin..."
  if [ "$OS" = "ubuntu" ]; then
    sudo apt-get install -qq -y --no-install-recommends ./session-manager-plugin.deb
  else
    sudo dnf install -y -q ./session-manager-plugin.rpm
  fi
}

if [ "$CACHE_ENABLED" = "false" ] || [ "$CACHE_HIT" = "false" ]; then
  download_plugin
fi

install_plugin

session-manager-plugin
