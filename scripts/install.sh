#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Keep this in sync with the `path:` of the cache step in action.yaml.
CACHE_PATH="$HOME/.cache/aws-ssm"

echo "::debug::CACHE_ENABLED=$CACHE_ENABLED"
echo "::debug::CACHE_HIT=$CACHE_HIT"
echo "::debug::CACHE_PATH=$CACHE_PATH"
echo "::debug::OS=$OS"
echo "::debug::ARCH=$ARCH"

mkdir -p "$CACHE_PATH"
cd "$CACHE_PATH"

REMOTE_URL_BASE="https://s3.amazonaws.com/session-manager-downloads/plugin/latest"

if [ "$OS" = "ubuntu" ]; then
  INSTALLER="session-manager-plugin.deb"
  URL="${REMOTE_URL_BASE}/ubuntu_${ARCH}/${INSTALLER}"
else
  INSTALLER="session-manager-plugin.rpm"
  URL="${REMOTE_URL_BASE}/linux_${ARCH}/${INSTALLER}"
fi

download_plugin() {
  echo "Downloading for $OS/$ARCH..."

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
    sudo apt-get install -qq -y --no-install-recommends "./${INSTALLER}"
  else
    sudo dnf install -y -q "./${INSTALLER}"
  fi
}

if [ "$CACHE_ENABLED" != "true" ]; then
  # Caching is off, so never reuse a leftover file from a previous run on a
  # self-hosted runner with a persistent HOME.
  rm -f "$INSTALLER"
  download_plugin
elif [ ! -f "$INSTALLER" ]; then
  # Trust the file, not the cache-hit flag: a restored cache can be stale or
  # hold the installer for a different distro family.
  if [ "$CACHE_HIT" = "true" ]; then
    echo "::warning::Cache hit but ${INSTALLER} is missing, downloading it again."
  fi
  download_plugin
fi

install_plugin

session-manager-plugin
